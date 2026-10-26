--
-- PostgreSQL database dump
--

\restrict zSXcwRdi6AEpfcNYbB0IW0rLqTvoOof6lfKFto88DK1pX6UptIDkTMoUMiBe6cd

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
-- Name: employee_loan_deductions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employee_loan_deductions (
    tenant_id integer DEFAULT 1 NOT NULL,
    id integer NOT NULL,
    employee_id integer NOT NULL,
    header_id integer NOT NULL,
    month integer NOT NULL,
    year integer NOT NULL,
    date date NOT NULL,
    amount numeric NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: employee_loan_deductions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.employee_loan_deductions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: employee_loan_deductions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.employee_loan_deductions_id_seq OWNED BY public.employee_loan_deductions.id;


--
-- Name: employee_loans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employee_loans (
    tenant_id integer DEFAULT 1 NOT NULL,
    id integer NOT NULL,
    employee_id integer NOT NULL,
    date date NOT NULL,
    amount numeric NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: employee_loans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.employee_loans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: employee_loans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.employee_loans_id_seq OWNED BY public.employee_loans.id;


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
-- Name: employee_loan_deductions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_loan_deductions ALTER COLUMN id SET DEFAULT nextval('public.employee_loan_deductions_id_seq'::regclass);


--
-- Name: employee_loans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_loans ALTER COLUMN id SET DEFAULT nextval('public.employee_loans_id_seq'::regclass);


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
0029_employee_loans.sql	2026-10-20 09:23:22.845727+00
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
19603	47	2026-10-01	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19604	47	2026-10-02	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19605	47	2026-10-03	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19606	47	2026-10-04	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19607	47	2026-10-05	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19608	47	2026-10-06	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19609	47	2026-10-07	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19610	47	2026-10-08	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19611	47	2026-10-09	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19612	47	2026-10-10	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19613	47	2026-10-11	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19614	47	2026-10-12	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19615	47	2026-10-13	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19616	47	2026-10-14	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
16340	18	2026-09-04	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
11021	16	2026-08-10	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11022	16	2026-08-11	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11023	16	2026-08-12	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11024	16	2026-08-13	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11025	16	2026-08-14	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11026	16	2026-08-15	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11027	16	2026-08-16	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11028	16	2026-08-17	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11029	16	2026-08-18	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11030	16	2026-08-19	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11031	16	2026-08-20	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11032	16	2026-08-21	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11033	16	2026-08-22	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11034	16	2026-08-23	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11035	16	2026-08-24	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11036	16	2026-08-25	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11037	16	2026-08-26	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11038	16	2026-08-27	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11039	16	2026-08-28	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11040	16	2026-08-29	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11041	16	2026-08-30	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11042	16	2026-08-31	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11043	17	2026-08-01	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11044	17	2026-08-02	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11045	17	2026-08-03	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11046	17	2026-08-04	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11047	17	2026-08-05	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11048	17	2026-08-06	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11049	17	2026-08-07	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11050	17	2026-08-08	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11051	17	2026-08-09	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11052	17	2026-08-10	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11053	17	2026-08-11	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11054	17	2026-08-12	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11055	17	2026-08-13	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11056	17	2026-08-14	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11057	17	2026-08-15	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11058	17	2026-08-16	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11059	17	2026-08-17	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11060	17	2026-08-18	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11061	17	2026-08-19	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11062	17	2026-08-20	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11063	17	2026-08-21	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11064	17	2026-08-22	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11065	17	2026-08-23	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11066	17	2026-08-24	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11067	17	2026-08-25	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11068	17	2026-08-26	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11069	17	2026-08-27	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11070	17	2026-08-28	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11071	17	2026-08-29	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11072	17	2026-08-30	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11073	17	2026-08-31	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11074	1	2026-08-14	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11075	1	2026-08-26	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11076	1	2026-08-31	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
16341	18	2026-09-05	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16342	18	2026-09-06	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16343	18	2026-09-08	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16344	18	2026-09-09	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16345	18	2026-09-10	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16346	18	2026-09-11	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16347	18	2026-09-12	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16348	18	2026-09-13	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16349	18	2026-09-14	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16350	18	2026-09-15	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16351	18	2026-09-16	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16352	18	2026-09-17	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16353	18	2026-09-18	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16354	18	2026-09-19	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16355	18	2026-09-20	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16356	18	2026-09-21	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16357	18	2026-09-22	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16358	18	2026-09-23	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16359	18	2026-09-25	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16360	18	2026-09-26	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16361	18	2026-09-27	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
11634	19	2026-09-01	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11635	19	2026-09-02	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11636	19	2026-09-03	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11637	19	2026-09-04	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11638	19	2026-09-05	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11639	19	2026-09-06	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11640	19	2026-09-07	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11641	19	2026-09-08	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
16362	18	2026-09-28	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16363	18	2026-09-29	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16364	18	2026-09-30	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16365	14	2026-09-01	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16366	14	2026-09-02	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16367	14	2026-09-03	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16368	14	2026-09-04	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16369	14	2026-09-05	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16370	14	2026-09-06	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16371	14	2026-09-07	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16372	14	2026-09-08	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16373	14	2026-09-09	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16374	14	2026-09-10	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16375	14	2026-09-11	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16376	14	2026-09-12	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16377	14	2026-09-13	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16378	14	2026-09-14	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16379	14	2026-09-15	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16380	14	2026-09-16	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16381	14	2026-09-17	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
10749	15	2026-08-01	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10750	15	2026-08-02	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10751	15	2026-08-03	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10752	15	2026-08-04	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10753	15	2026-08-05	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10754	15	2026-08-06	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10755	15	2026-08-07	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10756	15	2026-08-08	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10757	15	2026-08-09	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10758	15	2026-08-10	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10759	15	2026-08-11	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10760	15	2026-08-12	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10761	15	2026-08-13	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10762	15	2026-08-14	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10763	15	2026-08-15	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10764	15	2026-08-16	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10765	15	2026-08-17	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10766	15	2026-08-18	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10767	15	2026-08-19	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10768	15	2026-08-20	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10769	15	2026-08-21	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10770	15	2026-08-22	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10771	15	2026-08-23	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10772	15	2026-08-24	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10773	15	2026-08-25	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10774	15	2026-08-26	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10775	15	2026-08-27	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10776	15	2026-08-28	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10777	15	2026-08-29	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10778	15	2026-08-30	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10779	15	2026-08-31	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10780	8	2026-08-09	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10781	8	2026-08-10	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10782	8	2026-08-14	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10783	8	2026-08-25	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10784	8	2026-08-26	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10785	8	2026-08-30	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10786	8	2026-08-31	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10787	10	2026-08-01	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10788	10	2026-08-02	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10789	10	2026-08-03	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10790	10	2026-08-04	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10791	10	2026-08-05	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10792	10	2026-08-06	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10793	10	2026-08-07	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10794	10	2026-08-08	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10795	10	2026-08-09	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10796	10	2026-08-10	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10797	10	2026-08-11	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10798	10	2026-08-12	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10799	10	2026-08-13	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10800	10	2026-08-14	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10801	10	2026-08-15	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10802	10	2026-08-16	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10803	10	2026-08-17	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10804	10	2026-08-18	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10805	10	2026-08-19	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10806	10	2026-08-20	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10807	10	2026-08-21	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10808	10	2026-08-22	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10809	10	2026-08-23	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10810	10	2026-08-24	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10811	10	2026-08-25	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10812	10	2026-08-26	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10813	10	2026-08-27	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10814	10	2026-08-28	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10815	10	2026-08-29	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10816	10	2026-08-30	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10817	10	2026-08-31	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10818	11	2026-08-01	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10819	11	2026-08-02	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10820	11	2026-08-03	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10821	11	2026-08-04	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10822	11	2026-08-05	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10823	11	2026-08-06	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10824	11	2026-08-07	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10825	11	2026-08-08	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10826	11	2026-08-09	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10827	11	2026-08-10	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10828	11	2026-08-11	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10829	11	2026-08-12	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10830	11	2026-08-13	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10831	11	2026-08-14	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10832	11	2026-08-15	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10833	11	2026-08-16	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10834	11	2026-08-17	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10835	11	2026-08-18	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10836	11	2026-08-19	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10837	11	2026-08-20	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10838	11	2026-08-21	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10839	11	2026-08-22	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10840	11	2026-08-23	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10841	11	2026-08-24	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10842	11	2026-08-25	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10843	11	2026-08-26	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10844	11	2026-08-27	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10845	11	2026-08-28	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10846	11	2026-08-29	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10847	11	2026-08-30	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10848	11	2026-08-31	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10849	9	2026-08-14	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10850	9	2026-08-24	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10851	9	2026-08-25	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10852	9	2026-08-26	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10853	9	2026-08-31	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10854	12	2026-08-01	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10855	12	2026-08-02	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10856	12	2026-08-03	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10857	12	2026-08-04	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10858	12	2026-08-05	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10859	12	2026-08-06	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10860	12	2026-08-07	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10861	12	2026-08-08	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10862	12	2026-08-09	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10863	12	2026-08-10	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10864	12	2026-08-11	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10865	12	2026-08-12	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10866	12	2026-08-13	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10867	12	2026-08-14	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10868	12	2026-08-15	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10869	12	2026-08-16	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10870	12	2026-08-17	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10871	12	2026-08-18	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10872	12	2026-08-19	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10873	12	2026-08-20	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10874	12	2026-08-21	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10875	12	2026-08-22	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10876	12	2026-08-23	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10877	12	2026-08-24	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10878	12	2026-08-25	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10879	12	2026-08-26	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10880	12	2026-08-27	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10881	12	2026-08-28	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10882	12	2026-08-29	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10883	12	2026-08-30	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10884	12	2026-08-31	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10885	19	2026-08-01	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10886	19	2026-08-02	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10887	19	2026-08-03	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10888	19	2026-08-04	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10889	19	2026-08-05	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10890	19	2026-08-06	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10891	19	2026-08-07	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10892	19	2026-08-08	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10893	19	2026-08-09	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10894	19	2026-08-10	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10895	19	2026-08-11	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10896	19	2026-08-12	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10897	19	2026-08-13	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10898	19	2026-08-14	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10899	19	2026-08-15	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10900	19	2026-08-16	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10901	19	2026-08-17	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10902	19	2026-08-18	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10903	19	2026-08-19	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10904	19	2026-08-20	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10905	19	2026-08-21	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10906	19	2026-08-22	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10907	19	2026-08-23	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10908	19	2026-08-24	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10909	19	2026-08-25	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10910	19	2026-08-26	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10911	19	2026-08-27	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10912	19	2026-08-28	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10913	19	2026-08-29	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10914	19	2026-08-30	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10915	19	2026-08-31	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10916	2	2026-08-09	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10917	2	2026-08-14	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10918	2	2026-08-24	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10919	2	2026-08-25	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10920	2	2026-08-26	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10921	2	2026-08-31	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10922	18	2026-08-03	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10923	18	2026-08-05	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10924	18	2026-08-06	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10925	18	2026-08-07	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
19617	47	2026-10-15	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19618	47	2026-10-16	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
11664	3	2026-09-01	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11665	3	2026-09-02	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11666	3	2026-09-03	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11667	3	2026-09-04	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11668	3	2026-09-05	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11669	3	2026-09-06	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11670	3	2026-09-07	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11671	3	2026-09-08	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
19619	47	2026-10-17	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19620	47	2026-10-18	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19621	47	2026-10-24	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19622	47	2026-10-25	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19623	47	2026-10-26	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19624	20	2026-10-01	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
17066	8	2026-10-01	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17067	8	2026-10-02	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
11680	17	2026-09-01	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11681	17	2026-09-02	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11682	17	2026-09-03	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11683	17	2026-09-04	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11684	17	2026-09-05	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11685	17	2026-09-06	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11686	17	2026-09-07	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
11687	17	2026-09-08	f	2026-09-08 06:08:39.831505	2026-09-08 06:08:39.831505	1
17068	8	2026-10-03	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17069	8	2026-10-04	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17070	8	2026-10-05	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17071	8	2026-10-06	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17072	8	2026-10-07	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17073	8	2026-10-08	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17074	8	2026-10-09	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17075	8	2026-10-10	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17076	8	2026-10-11	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
19625	20	2026-10-02	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19626	20	2026-10-03	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19627	20	2026-10-04	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19628	20	2026-10-05	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19629	20	2026-10-06	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19630	20	2026-10-07	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19631	20	2026-10-08	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19632	20	2026-10-09	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19633	20	2026-10-10	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
16382	14	2026-09-18	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16383	14	2026-09-19	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16384	14	2026-09-20	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16385	14	2026-09-21	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16386	14	2026-09-22	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16387	14	2026-09-23	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16388	14	2026-09-24	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16389	14	2026-09-25	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16390	14	2026-09-26	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16391	14	2026-09-27	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16392	14	2026-09-28	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16393	14	2026-09-29	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16394	14	2026-09-30	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16395	16	2026-09-01	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16396	16	2026-09-02	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16397	16	2026-09-03	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16398	16	2026-09-04	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16399	16	2026-09-05	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16400	16	2026-09-06	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16138	20	2026-09-01	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16139	20	2026-09-02	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16140	20	2026-09-03	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16141	20	2026-09-04	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16142	20	2026-09-05	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16143	20	2026-09-06	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16144	20	2026-09-07	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16145	20	2026-09-08	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16146	20	2026-09-09	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16147	20	2026-09-10	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16148	20	2026-09-11	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16149	20	2026-09-12	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16150	20	2026-09-13	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16151	20	2026-09-14	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16152	20	2026-09-15	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16153	20	2026-09-16	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16154	20	2026-09-17	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16155	20	2026-09-18	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16156	20	2026-09-19	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16157	20	2026-09-20	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16158	20	2026-09-21	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16159	20	2026-09-22	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16160	20	2026-09-27	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16161	20	2026-09-28	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16162	20	2026-09-29	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16163	20	2026-09-30	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16164	15	2026-09-01	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16165	15	2026-09-02	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16166	15	2026-09-03	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16167	15	2026-09-04	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16168	15	2026-09-05	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16169	15	2026-09-06	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16170	15	2026-09-07	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16171	15	2026-09-08	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16172	15	2026-09-09	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16173	15	2026-09-10	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16174	15	2026-09-11	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16175	15	2026-09-12	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16176	15	2026-09-13	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16177	15	2026-09-14	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16178	15	2026-09-15	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16179	15	2026-09-16	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16180	15	2026-09-17	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16181	15	2026-09-18	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16182	15	2026-09-19	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16183	15	2026-09-20	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16184	15	2026-09-21	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16185	15	2026-09-22	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16186	15	2026-09-23	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16187	15	2026-09-24	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16188	15	2026-09-25	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16189	15	2026-09-26	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16190	15	2026-09-27	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16191	15	2026-09-28	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16192	15	2026-09-29	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16193	15	2026-09-30	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16194	8	2026-09-21	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16195	8	2026-09-22	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16196	8	2026-09-23	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16197	8	2026-09-24	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16198	8	2026-09-25	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16199	8	2026-09-26	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16200	8	2026-09-27	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16201	8	2026-09-28	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16202	8	2026-09-29	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16203	8	2026-09-30	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16204	10	2026-09-01	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16205	10	2026-09-02	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16206	10	2026-09-03	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16207	10	2026-09-04	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
19634	20	2026-10-11	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19635	20	2026-10-12	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19636	20	2026-10-13	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19637	20	2026-10-14	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19638	20	2026-10-15	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19639	20	2026-10-16	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19640	20	2026-10-24	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19641	20	2026-10-25	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19642	20	2026-10-26	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19643	15	2026-10-01	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19644	15	2026-10-02	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19645	15	2026-10-03	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19646	15	2026-10-04	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19647	15	2026-10-05	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19648	15	2026-10-06	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19649	15	2026-10-07	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19650	15	2026-10-08	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19651	15	2026-10-09	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19652	15	2026-10-10	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19653	15	2026-10-11	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19654	15	2026-10-12	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19655	15	2026-10-13	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19656	15	2026-10-14	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19657	15	2026-10-15	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19658	15	2026-10-16	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19659	15	2026-10-17	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19660	15	2026-10-18	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19661	15	2026-10-19	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19662	15	2026-10-20	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19663	15	2026-10-21	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19664	15	2026-10-22	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19665	15	2026-10-23	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19666	15	2026-10-24	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
17119	2	2026-10-01	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17120	2	2026-10-02	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17121	2	2026-10-03	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17122	2	2026-10-04	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17123	2	2026-10-05	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17124	2	2026-10-06	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17125	2	2026-10-07	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17126	2	2026-10-08	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17127	2	2026-10-09	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17128	2	2026-10-10	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
17129	2	2026-10-11	f	2026-10-11 08:10:48.929926	2026-10-11 08:10:48.929926	1
19667	15	2026-10-25	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19668	15	2026-10-26	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19669	10	2026-10-01	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19670	10	2026-10-02	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19671	10	2026-10-03	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19672	10	2026-10-04	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19673	10	2026-10-05	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19674	10	2026-10-06	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19675	10	2026-10-07	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19676	10	2026-10-08	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19677	10	2026-10-09	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19678	10	2026-10-10	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19679	10	2026-10-11	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19680	10	2026-10-12	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19681	10	2026-10-13	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19682	10	2026-10-14	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19683	10	2026-10-15	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19684	10	2026-10-16	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19685	10	2026-10-17	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19686	10	2026-10-18	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19687	10	2026-10-19	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19688	10	2026-10-20	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19689	10	2026-10-21	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19690	10	2026-10-22	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19691	10	2026-10-23	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19692	10	2026-10-24	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19693	10	2026-10-25	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19694	10	2026-10-26	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19695	11	2026-10-01	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19696	11	2026-10-02	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19697	11	2026-10-03	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19698	11	2026-10-04	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19699	11	2026-10-05	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19700	11	2026-10-06	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19701	11	2026-10-07	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19702	11	2026-10-08	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19703	11	2026-10-09	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19704	11	2026-10-10	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19705	11	2026-10-11	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19706	11	2026-10-12	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19707	11	2026-10-13	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19708	11	2026-10-14	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19709	11	2026-10-15	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19710	11	2026-10-16	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19711	11	2026-10-17	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19712	11	2026-10-18	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19713	11	2026-10-19	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19714	11	2026-10-20	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19715	11	2026-10-21	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19716	11	2026-10-22	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19717	11	2026-10-23	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19718	11	2026-10-24	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19719	11	2026-10-25	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19720	11	2026-10-26	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19721	30	2026-10-05	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19722	30	2026-10-06	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19723	30	2026-10-07	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19724	30	2026-10-08	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19725	30	2026-10-09	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19726	30	2026-10-10	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19727	30	2026-10-11	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19728	30	2026-10-12	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19729	30	2026-10-13	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19730	30	2026-10-14	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19731	30	2026-10-15	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19732	30	2026-10-16	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19733	30	2026-10-17	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19734	30	2026-10-18	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19735	30	2026-10-19	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19736	30	2026-10-20	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19737	30	2026-10-21	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19738	30	2026-10-22	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19739	30	2026-10-23	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19740	30	2026-10-24	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19741	30	2026-10-25	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19742	30	2026-10-26	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19743	9	2026-10-17	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19744	9	2026-10-18	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19745	9	2026-10-19	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19746	9	2026-10-20	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19747	9	2026-10-21	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19748	9	2026-10-22	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19749	9	2026-10-23	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19750	9	2026-10-24	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19751	9	2026-10-25	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19752	9	2026-10-26	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19753	12	2026-10-01	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19754	12	2026-10-02	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19755	12	2026-10-03	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19756	12	2026-10-04	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19757	12	2026-10-05	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19758	12	2026-10-06	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19759	12	2026-10-07	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19760	12	2026-10-08	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19761	12	2026-10-09	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19762	12	2026-10-10	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19763	12	2026-10-11	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19764	12	2026-10-12	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19765	12	2026-10-13	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19766	12	2026-10-14	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19767	12	2026-10-15	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19768	12	2026-10-16	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19769	12	2026-10-17	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19770	12	2026-10-18	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19771	12	2026-10-19	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19772	12	2026-10-20	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19773	12	2026-10-21	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19774	12	2026-10-22	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19775	12	2026-10-23	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19776	12	2026-10-24	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19777	12	2026-10-25	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19778	12	2026-10-26	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
15949	9	2026-09-29	t	2026-10-01 05:36:48.105956	2026-10-01 05:36:48.105956	1
15950	9	2026-09-30	t	2026-10-01 05:36:48.105956	2026-10-01 05:36:48.105956	1
19779	18	2026-10-01	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19780	18	2026-10-02	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19781	18	2026-10-03	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19782	18	2026-10-04	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19783	18	2026-10-05	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19784	18	2026-10-06	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19785	18	2026-10-07	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19786	18	2026-10-08	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19787	18	2026-10-09	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19788	18	2026-10-10	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19789	18	2026-10-11	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19790	18	2026-10-12	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19791	18	2026-10-13	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19792	18	2026-10-14	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19793	18	2026-10-15	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
16208	10	2026-09-05	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16209	10	2026-09-06	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16210	10	2026-09-07	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
19794	18	2026-10-16	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19795	18	2026-10-17	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19796	18	2026-10-18	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
10926	18	2026-08-08	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10927	18	2026-08-09	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10928	18	2026-08-12	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10929	18	2026-08-13	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10930	18	2026-08-14	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10931	18	2026-08-15	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10932	18	2026-08-16	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10933	18	2026-08-18	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10934	18	2026-08-19	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10935	18	2026-08-21	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10936	18	2026-08-22	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10937	18	2026-08-23	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10938	18	2026-08-24	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10939	18	2026-08-25	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10940	18	2026-08-26	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10941	18	2026-08-27	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10942	18	2026-08-28	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10943	18	2026-08-29	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10944	18	2026-08-31	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10945	7	2026-08-14	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10946	7	2026-08-24	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10947	7	2026-08-25	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10948	7	2026-08-26	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10949	7	2026-08-28	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10950	7	2026-08-31	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10951	14	2026-08-01	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
19797	18	2026-10-19	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19798	18	2026-10-20	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19799	18	2026-10-21	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19800	18	2026-10-22	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19801	18	2026-10-23	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19802	18	2026-10-24	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19803	18	2026-10-25	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19804	18	2026-10-26	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19805	48	2026-10-01	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
16211	10	2026-09-08	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16212	10	2026-09-09	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16213	10	2026-09-10	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16214	10	2026-09-11	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16215	10	2026-09-12	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16216	10	2026-09-13	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16217	10	2026-09-14	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
10952	14	2026-08-02	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10953	14	2026-08-03	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10954	14	2026-08-04	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10955	14	2026-08-05	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10956	14	2026-08-06	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10957	14	2026-08-07	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10958	14	2026-08-08	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10959	14	2026-08-09	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10960	14	2026-08-10	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10961	14	2026-08-11	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10962	14	2026-08-12	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10963	14	2026-08-13	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10964	14	2026-08-14	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10965	14	2026-08-15	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10966	14	2026-08-16	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10967	14	2026-08-17	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10968	14	2026-08-18	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10969	14	2026-08-19	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10970	14	2026-08-20	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10971	14	2026-08-21	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10972	14	2026-08-22	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10973	14	2026-08-23	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10974	14	2026-08-24	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10975	14	2026-08-25	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10976	14	2026-08-26	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10977	14	2026-08-27	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10978	14	2026-08-28	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10979	14	2026-08-29	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10980	14	2026-08-30	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10981	14	2026-08-31	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10982	3	2026-08-02	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10983	3	2026-08-03	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10984	3	2026-08-04	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10985	3	2026-08-05	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10986	3	2026-08-06	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10987	3	2026-08-07	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10988	3	2026-08-08	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10989	3	2026-08-09	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10990	3	2026-08-10	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10991	3	2026-08-11	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10992	3	2026-08-12	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10993	3	2026-08-13	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10994	3	2026-08-14	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10995	3	2026-08-15	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10996	3	2026-08-16	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10997	3	2026-08-17	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10998	3	2026-08-18	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
10999	3	2026-08-19	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11000	3	2026-08-20	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11001	3	2026-08-21	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11002	3	2026-08-22	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11003	3	2026-08-23	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11004	3	2026-08-24	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11005	3	2026-08-25	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11006	3	2026-08-26	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11007	3	2026-08-27	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11008	3	2026-08-28	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11009	3	2026-08-29	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11010	3	2026-08-30	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11011	3	2026-08-31	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11012	16	2026-08-01	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11013	16	2026-08-02	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11014	16	2026-08-03	f	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11015	16	2026-08-04	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11016	16	2026-08-05	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11017	16	2026-08-06	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11018	16	2026-08-07	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11019	16	2026-08-08	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
11020	16	2026-08-09	t	2026-09-01 06:21:27.563209	2026-09-01 06:21:27.563209	1
16218	10	2026-09-15	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16219	10	2026-09-16	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16220	10	2026-09-17	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16221	10	2026-09-18	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16222	10	2026-09-19	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16223	10	2026-09-20	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16224	10	2026-09-21	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16225	10	2026-09-22	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16226	10	2026-09-23	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16227	10	2026-09-24	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16228	10	2026-09-25	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
19806	48	2026-10-02	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19807	48	2026-10-03	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19808	48	2026-10-04	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19809	48	2026-10-05	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19810	48	2026-10-06	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19811	48	2026-10-07	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19812	48	2026-10-08	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19813	48	2026-10-09	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19814	48	2026-10-10	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19815	48	2026-10-11	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19816	48	2026-10-12	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19817	48	2026-10-13	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19818	48	2026-10-14	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19819	48	2026-10-15	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19820	48	2026-10-16	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19821	48	2026-10-17	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19822	48	2026-10-18	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19823	48	2026-10-19	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19824	48	2026-10-20	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19825	48	2026-10-21	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19826	48	2026-10-22	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19827	48	2026-10-23	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19828	48	2026-10-24	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19829	48	2026-10-25	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19830	48	2026-10-26	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19831	46	2026-10-01	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19832	46	2026-10-02	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19833	46	2026-10-03	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
16229	10	2026-09-26	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16230	10	2026-09-27	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16231	10	2026-09-28	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16232	10	2026-09-29	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16233	10	2026-09-30	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16234	11	2026-09-01	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16235	11	2026-09-02	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16236	11	2026-09-03	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16237	11	2026-09-04	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16238	11	2026-09-05	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16239	11	2026-09-06	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16240	11	2026-09-07	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16241	11	2026-09-08	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16242	11	2026-09-09	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16243	11	2026-09-10	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16244	11	2026-09-11	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16245	11	2026-09-12	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16246	11	2026-09-13	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16247	11	2026-09-14	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16248	11	2026-09-15	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16249	11	2026-09-16	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16250	11	2026-09-17	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16251	11	2026-09-18	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16252	11	2026-09-19	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16253	11	2026-09-20	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16254	11	2026-09-21	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16255	11	2026-09-22	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16256	11	2026-09-23	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16257	11	2026-09-24	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
19834	46	2026-10-04	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19835	46	2026-10-05	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19836	46	2026-10-06	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19837	46	2026-10-07	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19838	46	2026-10-24	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19839	46	2026-10-25	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19840	46	2026-10-26	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19841	7	2026-10-24	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19842	7	2026-10-25	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19843	7	2026-10-26	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19844	14	2026-10-01	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19845	14	2026-10-02	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19846	14	2026-10-03	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19847	14	2026-10-04	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19848	14	2026-10-05	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19849	14	2026-10-06	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19850	14	2026-10-07	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
16023	7	2026-09-29	t	2026-10-01 05:36:48.105956	2026-10-01 05:36:48.105956	1
16024	7	2026-09-30	t	2026-10-01 05:36:48.105956	2026-10-01 05:36:48.105956	1
19851	14	2026-10-08	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19852	14	2026-10-09	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19853	14	2026-10-10	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19854	14	2026-10-11	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
16258	11	2026-09-25	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16259	11	2026-09-26	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16260	11	2026-09-27	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16261	11	2026-09-28	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16262	11	2026-09-29	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16263	11	2026-09-30	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16264	30	2026-09-01	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16265	30	2026-09-02	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16266	30	2026-09-03	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16267	30	2026-09-04	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16268	30	2026-09-05	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16269	30	2026-09-06	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16270	30	2026-09-07	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16271	30	2026-09-08	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16272	30	2026-09-09	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16273	30	2026-09-10	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16274	30	2026-09-11	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16275	30	2026-09-12	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16276	30	2026-09-13	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16277	30	2026-09-14	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16278	30	2026-09-15	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16279	30	2026-09-16	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
19855	14	2026-10-12	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19856	14	2026-10-13	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19857	14	2026-10-14	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19858	14	2026-10-15	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19859	14	2026-10-16	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19860	14	2026-10-17	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19861	14	2026-10-18	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19862	14	2026-10-19	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19863	14	2026-10-20	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19864	14	2026-10-21	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19865	14	2026-10-22	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19866	14	2026-10-23	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19867	14	2026-10-24	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19868	14	2026-10-25	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19869	14	2026-10-26	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19870	16	2026-10-01	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19871	16	2026-10-02	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19872	16	2026-10-03	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
16280	30	2026-09-17	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16281	30	2026-09-18	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16282	30	2026-09-19	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16283	30	2026-09-20	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16284	30	2026-09-21	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16285	30	2026-09-22	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16286	30	2026-09-23	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16287	30	2026-09-24	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16288	30	2026-09-25	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
19873	16	2026-10-04	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
16289	30	2026-09-26	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16290	30	2026-09-27	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16291	30	2026-09-28	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16292	30	2026-09-29	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16293	12	2026-09-01	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16294	12	2026-09-02	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16295	12	2026-09-03	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16296	12	2026-09-04	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16297	12	2026-09-05	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16298	12	2026-09-06	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16299	12	2026-09-07	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16300	12	2026-09-08	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16301	12	2026-09-09	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16302	12	2026-09-10	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16303	12	2026-09-11	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16304	12	2026-09-12	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16305	12	2026-09-13	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16306	12	2026-09-14	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16307	12	2026-09-15	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16308	12	2026-09-16	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16309	12	2026-09-17	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16310	12	2026-09-18	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16311	12	2026-09-19	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16312	12	2026-09-20	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16313	12	2026-09-21	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16314	12	2026-09-22	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16315	12	2026-09-23	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16316	12	2026-09-24	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16317	12	2026-09-25	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16318	12	2026-09-26	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16319	12	2026-09-27	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16320	12	2026-09-28	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16321	12	2026-09-29	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16322	12	2026-09-30	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16323	2	2026-09-01	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16324	2	2026-09-04	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16325	2	2026-09-17	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16326	2	2026-09-20	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16327	2	2026-09-21	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16328	2	2026-09-22	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16329	2	2026-09-23	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16330	2	2026-09-24	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16331	2	2026-09-25	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16332	2	2026-09-26	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16333	2	2026-09-27	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16334	2	2026-09-28	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16335	2	2026-09-29	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16336	2	2026-09-30	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16337	18	2026-09-01	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16338	18	2026-09-02	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16339	18	2026-09-03	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16401	16	2026-09-07	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16402	16	2026-09-08	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16403	16	2026-09-09	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16404	16	2026-09-10	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16405	16	2026-09-11	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16406	16	2026-09-12	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16407	16	2026-09-13	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16408	16	2026-09-14	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16409	16	2026-09-15	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16410	16	2026-09-16	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16411	16	2026-09-17	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16412	16	2026-09-18	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16413	16	2026-09-19	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16414	16	2026-09-20	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16415	16	2026-09-21	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16416	16	2026-09-22	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16417	16	2026-09-23	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16418	16	2026-09-24	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16419	16	2026-09-25	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16420	16	2026-09-26	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16421	16	2026-09-27	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16422	16	2026-09-28	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16423	16	2026-09-29	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16424	16	2026-09-30	t	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16425	1	2026-09-06	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16426	1	2026-09-07	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16427	1	2026-09-08	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16428	1	2026-09-09	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16429	1	2026-09-10	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16430	1	2026-09-11	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16431	1	2026-09-12	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16432	1	2026-09-13	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
16433	1	2026-09-14	f	2026-10-02 09:31:55.589158	2026-10-02 09:31:55.589158	1
19874	16	2026-10-05	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19875	16	2026-10-06	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19876	16	2026-10-07	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19877	16	2026-10-08	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19878	16	2026-10-09	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19879	16	2026-10-10	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19880	16	2026-10-11	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19881	16	2026-10-12	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19882	16	2026-10-13	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19883	16	2026-10-14	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19884	16	2026-10-15	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19885	16	2026-10-16	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19886	16	2026-10-17	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19887	16	2026-10-18	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19888	16	2026-10-19	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19889	16	2026-10-20	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19890	16	2026-10-21	f	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19891	16	2026-10-22	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19892	16	2026-10-23	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19893	16	2026-10-24	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19894	16	2026-10-25	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19895	16	2026-10-26	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19896	1	2026-10-24	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19897	1	2026-10-25	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
19898	1	2026-10-26	t	2026-10-26 08:59:21.494877	2026-10-26 08:59:21.494877	1
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
1	1	TKT Textiles	TKT	/api/uploads/TKTLogo-e8d73beaa21b.png	TKTLogo.png	TKTLogo-e8d73beaa21b.png	/api/uploads/TKTLogo-e5c3e8964d92.png	#0E7490	#06B6D4	#2DD4BF	#083344	#ECFEFF	#E5E7EB	#155E75	#FFFFFF	#164E63	#A5F3FC	#14B8A6	#10B981	#F59E0B	#EF4444	#3B82F6	Inter, sans-serif	16	6	pill	\N	\N	\N	\N	active	2026-08-26 19:07:51.881144	2026-08-26 19:07:51.881144
\.


--
-- Data for Name: company_info_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.company_info_master (id, name, ntn_cnic, province, address, fbr_sandbox_token, fbr_production_token, is_default, created_at, updated_at, tenant_id) FROM stdin;
1	TKT TEXTILES	4636080	Sindh	SHADE # 1-A, PLOT NO.L-39/1, BLOCK # 22, F.B. INDUSTRIAL AREA, Karachi Central, Karachi	0df2cdcf-d19a-34da-abf4-ca470c74a565	a20c225b-60e1-3d44-9966-41007b99d358	t	2026-08-12 17:58:06.278128	2026-10-03 09:32:51.923	1
\.


--
-- Data for Name: configuration; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.configuration (id, name, code, description, enabled, tenant_id) FROM stdin;
1	Reconciled lock	0001	used to enable/disable Reconciliation lock in daily operations	t	1
3	Allow Backdated Invoices	0003	when enabled, shows the manual "Create Backdated Invoice" tool to record invoices generated from another system	f	1
2	FBR DI Sandbox	0002	used to enable/disable FBR Digital Invoicing sandbox environment; when enabled invoices post to sandbox, when disabled they post to production	f	1
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
137	2026-09-29	16	3863	\N	\N	26	707.500	submitted	Iftikhar Ahmed	2026-09-29 11:14:14.69139	\N	2026-09-29 11:14:14.69139	t	416	2026-09-30 06:39:02.048	20	1
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
139	2026-09-28	16	3860	\N	\N	8	199.550	submitted	Iftikhar Ahmed	2026-09-30 05:17:15.945129	\N	2026-09-30 05:17:15.945129	t	414	2026-09-30 06:34:19.681	22	1
140	2026-09-30	16	3865	\N	\N	30	805.500	submitted	Iftikhar Ahmed	2026-09-30 09:23:49.478825	\N	2026-09-30 09:23:49.478825	t	419	2026-09-30 10:27:29.405	20	1
141	2026-09-30	16	3865	\N	\N	6	143.350	submitted	Iftikhar Ahmed	2026-09-30 09:24:57.023664	\N	2026-09-30 09:24:57.023664	t	419	2026-09-30 10:27:29.405	23	1
54	2026-08-25	17	3785	\N	\N	34	913.400	submitted	Iftikhar Ahmed	2026-08-25 11:10:01.614692	\N	2026-08-25 11:10:01.614692	t	272	2026-08-28 07:04:36.559	20	1
55	2026-08-25	17	3785	\N	\N	9	194.150	submitted	Iftikhar Ahmed	2026-08-25 11:11:00.752876	\N	2026-08-25 11:11:00.752876	t	272	2026-08-28 07:04:36.559	23	1
56	2026-08-25	17	3786	\N	\N	28	789.600	submitted	Iftikhar Ahmed	2026-08-25 11:11:45.082051	\N	2026-08-25 11:11:45.082051	t	272	2026-08-28 07:04:36.559	20	1
57	2026-08-25	17	3786	\N	\N	9	204.200	submitted	Iftikhar Ahmed	2026-08-25 11:12:35.03495	\N	2026-08-25 11:12:35.03495	t	272	2026-08-28 07:04:36.559	23	1
58	2026-08-25	17	3787	\N	\N	30	786.650	submitted	Iftikhar Ahmed	2026-08-25 11:13:35.366069	\N	2026-08-25 11:13:35.366069	t	272	2026-08-28 07:04:36.559	20	1
59	2026-08-25	17	3787	\N	\N	9	196.900	submitted	Iftikhar Ahmed	2026-08-25 11:14:27.498385	\N	2026-08-25 11:14:27.498385	t	272	2026-08-28 07:04:36.559	23	1
60	2026-08-27	16	3790	\N	\N	15	367.850	submitted	Iftikhar Ahmed	2026-08-27 14:18:28.533815	\N	2026-08-27 14:18:28.533815	t	273	2026-08-28 07:06:37.929	20	1
61	2026-08-27	16	3791	\N	\N	28	733.000	submitted	Iftikhar Ahmed	2026-08-27 14:19:17.40633	\N	2026-08-27 14:19:17.40633	t	273	2026-08-28 07:06:37.929	20	1
62	2026-08-27	16	3791	\N	\N	8	162.550	submitted	Iftikhar Ahmed	2026-08-27 14:19:59.577549	\N	2026-08-27 14:19:59.577549	t	273	2026-08-28 07:06:37.929	23	1
63	2026-08-29	15	3792	\N	\N	44	1212.800	submitted	Iftikhar Ahmed	2026-08-29 11:58:13.518339	\N	2026-08-29 11:58:13.518339	t	294	2026-08-31 09:21:09.143	20	1
64	2026-08-29	16	3793	\N	\N	30	804.350	submitted	Iftikhar Ahmed	2026-08-29 13:43:24.635602	\N	2026-08-29 13:43:24.635602	t	295	2026-08-31 09:28:09.462	20	1
65	2026-08-29	16	3793	\N	\N	5	119.500	submitted	Iftikhar Ahmed	2026-08-29 13:44:05.047381	\N	2026-08-29 13:44:05.047381	t	295	2026-08-31 09:28:09.462	23	1
66	2026-08-29	16	3794	\N	\N	30	810.050	submitted	Iftikhar Ahmed	2026-08-29 13:44:56.516675	\N	2026-08-29 13:44:56.516675	t	295	2026-08-31 09:28:09.462	20	1
67	2026-08-29	16	3794	\N	\N	5	117.800	submitted	Iftikhar Ahmed	2026-08-29 13:45:34.45745	\N	2026-08-29 13:45:34.45745	t	295	2026-08-31 09:28:09.462	23	1
68	2026-08-29	16	3795	\N	\N	17	415.550	submitted	Iftikhar Ahmed	2026-08-29 13:46:10.857353	\N	2026-08-29 13:46:10.857353	t	295	2026-08-31 09:28:09.462	22	1
69	2026-08-31	13	3796	\N	\N	42	1035.200	submitted	Iftikhar Ahmed	2026-08-31 09:28:00.493513	\N	2026-08-31 09:28:00.493513	t	296	2026-08-31 09:34:34.635	20	1
70	2026-08-31	15	3797	\N	\N	24	668.750	submitted	Iftikhar Ahmed	2026-08-31 12:59:04.530526	\N	2026-08-31 12:59:04.530526	t	298	2026-08-31 13:05:14.722	20	1
72	2026-09-01	16	3799	\N	\N	30	800.400	submitted	Iftikhar Ahmed	2026-09-01 11:21:36.106911	\N	2026-09-01 11:21:36.106911	t	302	2026-09-02 07:30:27.307	20	1
73	2026-09-01	16	3799	\N	\N	5	120.400	submitted	Iftikhar Ahmed	2026-09-01 11:22:22.576933	\N	2026-09-01 11:22:22.576933	t	302	2026-09-02 07:30:27.307	23	1
74	2026-09-02	13	3800	\N	\N	47	1204.900	submitted	Iftikhar Ahmed	2026-09-02 06:52:33.355603	\N	2026-09-02 06:52:33.355603	t	303	2026-09-02 07:31:36.338	20	1
71	2026-09-01	13	3798	\N	\N	33	815.600	submitted	Iftikhar Ahmed	2026-09-01 09:30:12.851689	\N	2026-09-01 09:30:12.851689	t	304	2026-09-02 07:33:22.096	20	1
75	2026-09-03	16	3801	\N	\N	38	998.100	submitted	Iftikhar Ahmed	2026-09-03 07:59:32.740265	\N	2026-09-03 07:59:32.740265	t	317	2026-09-04 06:47:58.858	20	1
76	2026-09-03	16	3801	\N	\N	7	145.850	submitted	Iftikhar Ahmed	2026-09-03 08:00:09.687921	\N	2026-09-03 08:00:09.687921	t	317	2026-09-04 06:47:58.858	23	1
78	2026-09-03	16	3803	\N	\N	60	1615.400	submitted	Iftikhar Ahmed	2026-09-03 13:50:25.250713	\N	2026-09-03 13:50:25.250713	t	317	2026-09-04 06:47:58.858	20	1
79	2026-09-03	16	3804	\N	\N	5	136.350	submitted	Iftikhar Ahmed	2026-09-03 13:51:18.677454	\N	2026-09-03 13:51:18.677454	t	317	2026-09-04 06:47:58.858	20	1
80	2026-09-03	16	3804	\N	\N	12	277.800	submitted	Iftikhar Ahmed	2026-09-03 13:51:56.994799	\N	2026-09-03 13:51:56.994799	t	317	2026-09-04 06:47:58.858	23	1
77	2026-09-03	13	3802	\N	\N	42	1089.800	submitted	Iftikhar Ahmed	2026-09-03 10:12:47.533615	\N	2026-09-03 10:12:47.533615	t	318	2026-09-04 06:50:00.762	20	1
82	2026-09-04	17	3806	\N	\N	30	858.250	submitted	Iftikhar Ahmed	2026-09-04 11:50:31.169278	\N	2026-09-04 11:50:31.169278	t	319	2026-09-05 05:46:48.857	20	1
83	2026-09-04	17	3806	\N	\N	10	225.250	submitted	Iftikhar Ahmed	2026-09-04 11:51:19.063343	\N	2026-09-04 11:51:19.063343	t	319	2026-09-05 05:46:48.857	23	1
84	2026-09-04	17	3807	\N	\N	31	867.250	submitted	Iftikhar Ahmed	2026-09-04 11:52:46.381993	\N	2026-09-04 11:52:46.381993	t	319	2026-09-05 05:46:48.857	20	1
85	2026-09-04	17	3807	\N	\N	11	218.300	submitted	Iftikhar Ahmed	2026-09-04 11:53:28.589647	\N	2026-09-04 11:53:28.589647	t	319	2026-09-05 05:46:48.857	23	1
81	2026-09-04	13	3805	\N	\N	46	1168.150	submitted	Iftikhar Ahmed	2026-09-04 11:45:17.703461	\N	2026-09-04 11:45:17.703461	t	320	2026-09-05 06:03:32.729	20	1
86	2026-09-05	13	3808	960+720+370	\N	17	430.450	submitted	Iftikhar Ahmed	2026-09-05 07:10:30.482497	\N	2026-09-05 07:10:30.482497	t	324	2026-09-05 09:26:34.475	20	1
87	2026-09-07	15	3809	\N	\N	38	1048.900	submitted	Iftikhar Ahmed	2026-09-07 07:44:49.902852	\N	2026-09-07 07:44:49.902852	t	330	2026-09-07 09:35:40.869	20	1
89	2026-09-07	16	3812	\N	\N	37	935.450	submitted	Iftikhar Ahmed	2026-09-07 13:24:00.841705	\N	2026-09-07 13:24:00.841705	t	333	2026-09-08 06:44:45.728	20	1
90	2026-09-07	16	3812	\N	\N	14	318.100	submitted	Iftikhar Ahmed	2026-09-07 13:24:50.560402	\N	2026-09-07 13:24:50.560402	t	333	2026-09-08 06:44:45.728	23	1
91	2026-09-07	16	3813	\N	\N	16	456.250	submitted	Iftikhar Ahmed	2026-09-07 13:25:42.284634	\N	2026-09-07 13:25:42.284634	t	333	2026-09-08 06:44:45.728	22	1
92	2026-09-07	16	3814	\N	\N	10	227.850	submitted	Iftikhar Ahmed	2026-09-07 13:26:59.691916	\N	2026-09-07 13:26:59.691916	t	333	2026-09-08 06:44:45.728	23	1
88	2026-09-07	13	3810	\N	\N	47	1209.550	submitted	Iftikhar Ahmed	2026-09-07 08:04:55.555511	\N	2026-09-07 08:04:55.555511	t	334	2026-09-08 06:46:33.245	20	1
93	2026-09-09	13	3815	960+720+370	\N	32	799.550	submitted	Iftikhar Ahmed	2026-09-09 10:04:11.503728	\N	2026-09-09 10:04:11.503728	t	344	2026-09-10 09:35:12.649	20	1
94	2026-09-09	13	3816	960+720+370	\N	20	556.600	submitted	Iftikhar Ahmed	2026-09-09 10:05:02.977559	\N	2026-09-09 10:05:02.977559	t	344	2026-09-10 09:35:12.649	20	1
95	2026-09-09	17	3817	1020+680+414	330	25	740.750	submitted	Iftikhar Ahmed	2026-09-09 10:06:23.47762	\N	2026-09-09 10:06:23.47762	t	345	2026-09-10 09:44:42.679	20	1
96	2026-09-09	17	3817	768	\N	12	237.650	submitted	Iftikhar Ahmed	2026-09-09 10:07:46.872285	\N	2026-09-09 10:07:46.872285	t	345	2026-09-10 09:44:42.679	23	1
98	2026-09-10	16	3819	\N	\N	18	495.500	submitted	Iftikhar Ahmed	2026-09-10 14:44:45.478927	\N	2026-09-10 14:44:45.478927	t	349	2026-09-11 06:44:49.879	20	1
99	2026-09-10	16	3820	\N	\N	60	1597.750	submitted	Iftikhar Ahmed	2026-09-10 14:45:26.376705	\N	2026-09-10 14:45:26.376705	t	349	2026-09-11 06:44:49.879	20	1
100	2026-09-10	16	3821	\N	\N	13	358.200	submitted	Iftikhar Ahmed	2026-09-10 14:46:05.249163	\N	2026-09-10 14:46:05.249163	t	349	2026-09-11 06:44:49.879	20	1
101	2026-09-10	16	3822	\N	\N	18	458.250	submitted	Iftikhar Ahmed	2026-09-10 14:46:55.799568	\N	2026-09-10 14:46:55.799568	t	349	2026-09-11 06:44:49.879	20	1
102	2026-09-10	16	3822	\N	\N	10	201.500	submitted	Iftikhar Ahmed	2026-09-10 14:47:34.959815	Iftikhar Ahmed	2026-09-11 04:32:13.677	t	349	2026-09-11 06:44:49.879	23	1
97	2026-09-10	16	3818	\N	\N	12	261.500	submitted	Iftikhar Ahmed	2026-09-10 14:43:58.683951	Iftikhar Ahmed	2026-09-11 04:32:27.875	t	349	2026-09-11 06:44:49.879	23	1
103	2026-09-12	23	3823	\N	\N	1	24.050	submitted	Iftikhar Ahmed	2026-09-12 10:13:06.080714	\N	2026-09-12 10:13:06.080714	t	360	2026-09-14 08:06:33.951	20	1
104	2026-09-14	14	3825	\N	\N	60	1476.450	submitted	Iftikhar Ahmed	2026-09-14 07:33:59.783997	\N	2026-09-14 07:33:59.783997	t	362	2026-09-14 08:12:17.253	20	1
105	2026-09-14	14	3826	\N	\N	11	279.400	submitted	Iftikhar Ahmed	2026-09-14 07:35:25.567529	\N	2026-09-14 07:35:25.567529	t	362	2026-09-14 08:12:17.253	20	1
106	2026-09-14	14	3827	\N	\N	22	609.450	submitted	Iftikhar Ahmed	2026-09-14 07:36:21.342433	\N	2026-09-14 07:36:21.342433	t	362	2026-09-14 08:12:17.253	20	1
107	2026-09-15	14	3829	\N	\N	60	1661.850	submitted	Iftikhar Ahmed	2026-09-15 12:46:40.120047	\N	2026-09-15 12:46:40.120047	t	367	2026-09-16 05:31:29.277	20	1
109	2026-09-15	16	3831	\N	\N	60	1548.100	submitted	Iftikhar Ahmed	2026-09-15 12:48:04.701918	\N	2026-09-15 12:48:04.701918	t	368	2026-09-16 05:33:48.722	20	1
110	2026-09-15	16	3832	\N	\N	17	454.150	submitted	Iftikhar Ahmed	2026-09-15 12:49:02.677825	\N	2026-09-15 12:49:02.677825	t	368	2026-09-16 05:33:48.722	20	1
108	2026-09-15	14	3830	\N	\N	3	83.700	submitted	Iftikhar Ahmed	2026-09-15 12:47:23.832887	\N	2026-09-15 12:47:23.832887	t	367	2026-09-16 05:31:29.277	20	1
111	2026-09-15	16	3832	\N	\N	14	303.950	submitted	Iftikhar Ahmed	2026-09-15 13:08:04.756178	\N	2026-09-15 13:08:04.756178	t	368	2026-09-16 05:33:48.722	23	1
138	2026-09-29	16	3863	\N	\N	5	115.750	submitted	Iftikhar Ahmed	2026-09-29 11:14:50.929298	\N	2026-09-29 11:14:50.929298	t	416	2026-09-30 06:39:02.048	23	1
133	2026-09-29	16	3861	\N	\N	26	701.200	submitted	Iftikhar Ahmed	2026-09-29 11:11:03.328892	\N	2026-09-29 11:11:03.328892	t	416	2026-09-30 06:39:02.048	20	1
112	2026-09-18	14	3837	\N	\N	60	1646.050	submitted	Iftikhar Ahmed	2026-09-18 11:10:22.376915	\N	2026-09-18 11:10:22.376915	t	376	2026-09-18 12:03:10.398	20	1
113	2026-09-18	14	3838	\N	\N	4	95.350	submitted	Iftikhar Ahmed	2026-09-18 11:11:19.438834	\N	2026-09-18 11:11:19.438834	t	376	2026-09-18 12:03:10.398	20	1
134	2026-09-29	16	3861	\N	\N	4	114.800	submitted	Iftikhar Ahmed	2026-09-29 11:11:51.76816	\N	2026-09-29 11:11:51.76816	t	416	2026-09-30 06:39:02.048	23	1
135	2026-09-29	16	3862	\N	\N	26	699.400	submitted	Iftikhar Ahmed	2026-09-29 11:12:46.50466	\N	2026-09-29 11:12:46.50466	t	416	2026-09-30 06:39:02.048	20	1
136	2026-09-29	16	3862	\N	\N	4	117.950	submitted	Iftikhar Ahmed	2026-09-29 11:13:23.255185	\N	2026-09-29 11:13:23.255185	t	416	2026-09-30 06:39:02.048	23	1
114	2026-09-19	16	3839	\N	\N	56	1511.900	submitted	Iftikhar Ahmed	2026-09-19 11:39:32.864195	\N	2026-09-19 11:39:32.864195	t	383	2026-09-21 08:15:40.914	20	1
115	2026-09-19	16	3840	\N	\N	4	80.950	submitted	Iftikhar Ahmed	2026-09-19 11:40:10.716666	\N	2026-09-19 11:40:10.716666	t	383	2026-09-21 08:15:40.914	23	1
116	2026-09-21	14	3841	\N	\N	60	1616.900	submitted	Iftikhar Ahmed	2026-09-21 08:05:00.816632	\N	2026-09-21 08:05:00.816632	t	384	2026-09-21 08:18:04.533	20	1
117	2026-09-21	14	3842	\N	\N	5	121.550	submitted	Iftikhar Ahmed	2026-09-21 08:06:06.609681	\N	2026-09-21 08:06:06.609681	t	384	2026-09-21 08:18:04.533	20	1
142	2026-09-30	16	3866	\N	\N	10	273.050	submitted	Iftikhar Ahmed	2026-09-30 13:00:10.324761	\N	2026-09-30 13:00:10.324761	t	420	2026-09-30 16:53:14.655	20	1
118	2026-09-21	14	3843	\N	\N	60	1661.100	submitted	Iftikhar Ahmed	2026-09-21 10:09:44.837705	\N	2026-09-21 10:09:44.837705	t	387	2026-09-22 06:00:58.438	20	1
119	2026-09-21	14	3844	\N	\N	3	84.550	submitted	Iftikhar Ahmed	2026-09-21 10:10:20.447252	\N	2026-09-21 10:10:20.447252	t	387	2026-09-22 06:00:58.438	20	1
143	2026-10-05	16	3867	\N	\N	26	717.150	submitted	Iftikhar Ahmed	2026-10-05 10:24:03.682425	\N	2026-10-05 10:24:03.682425	t	429	2026-10-06 10:18:44.904	20	1
145	2026-10-05	16	3868	\N	\N	7	154.200	submitted	Iftikhar Ahmed	2026-10-05 12:31:25.869901	\N	2026-10-05 12:31:25.869901	t	429	2026-10-06 10:18:44.904	23	1
120	2026-09-23	14	3846	\N	\N	60	1620.600	submitted	Iftikhar Ahmed	2026-09-23 10:27:09.498547	\N	2026-09-23 10:27:09.498547	t	397	2026-09-24 08:26:40.89	20	1
121	2026-09-23	14	3847	\N	\N	5	122.050	submitted	Iftikhar Ahmed	2026-09-23 10:27:49.270294	\N	2026-09-23 10:27:49.270294	t	397	2026-09-24 08:26:40.89	20	1
122	2026-09-23	14	3848	\N	\N	56	1523.100	submitted	Iftikhar Ahmed	2026-09-23 10:28:29.063514	\N	2026-09-23 10:28:29.063514	t	397	2026-09-24 08:26:40.89	20	1
123	2026-09-23	14	3849	\N	\N	9	221.750	submitted	Iftikhar Ahmed	2026-09-23 10:29:10.605958	\N	2026-09-23 10:29:10.605958	t	397	2026-09-24 08:26:40.89	20	1
144	2026-10-05	16	3868	\N	\N	31	803.300	submitted	Iftikhar Ahmed	2026-10-05 12:30:05.450076	\N	2026-10-05 12:30:05.450076	t	429	2026-10-06 10:18:44.904	20	1
146	2026-10-05	16	3869	\N	\N	31	804.100	submitted	Iftikhar Ahmed	2026-10-05 12:32:21.096998	\N	2026-10-05 12:32:21.096998	t	429	2026-10-06 10:18:44.904	20	1
147	2026-10-05	16	3869	\N	\N	6	152.850	submitted	Iftikhar Ahmed	2026-10-05 12:32:57.18836	\N	2026-10-05 12:32:57.18836	t	429	2026-10-06 10:18:44.904	23	1
125	2026-09-24	14	3852	\N	\N	60	1634.800	submitted	Iftikhar Ahmed	2026-09-24 12:26:03.214516	\N	2026-09-24 12:26:03.214516	t	400	2026-09-25 07:29:12.867	20	1
126	2026-09-24	14	3853	\N	\N	4	106.350	submitted	Iftikhar Ahmed	2026-09-24 12:26:37.972085	\N	2026-09-24 12:26:37.972085	t	400	2026-09-25 07:29:12.867	20	1
124	2026-09-24	16	3851	\N	\N	46	1202.550	submitted	Iftikhar Ahmed	2026-09-24 10:54:16.317532	\N	2026-09-24 10:54:16.317532	t	402	2026-09-25 09:18:54.321	20	1
127	2026-09-25	14	3854	\N	\N	60	1556.350	submitted	Iftikhar Ahmed	2026-09-25 10:20:42.261868	\N	2026-09-25 10:20:42.261868	t	405	2026-09-26 08:10:30.183	20	1
128	2026-09-25	14	3855	\N	\N	6	179.750	submitted	Iftikhar Ahmed	2026-09-25 10:21:23.087519	\N	2026-09-25 10:21:23.087519	t	405	2026-09-26 08:10:30.183	20	1
148	2026-10-06	16	3870	\N	\N	60	1658.050	submitted	Iftikhar Ahmed	2026-10-06 12:23:37.081673	\N	2026-10-06 12:23:37.081673	t	432	2026-10-07 06:56:00.499	20	1
149	2026-10-06	16	3871	\N	\N	31	844.750	submitted	Iftikhar Ahmed	2026-10-06 12:26:02.847134	\N	2026-10-06 12:26:02.847134	t	432	2026-10-07 06:56:00.499	20	1
150	2026-10-06	16	3871	\N	\N	18	407.950	submitted	Iftikhar Ahmed	2026-10-06 12:26:54.70415	\N	2026-10-06 12:26:54.70415	t	432	2026-10-07 06:56:00.499	23	1
151	2026-10-06	16	3873	\N	\N	59	1422.350	submitted	Iftikhar Ahmed	2026-10-06 12:27:44.15013	\N	2026-10-06 12:27:44.15013	t	432	2026-10-07 06:56:00.499	22	1
129	2026-09-28	14	3856	\N	\N	60	1643.200	submitted	Iftikhar Ahmed	2026-09-28 08:19:32.685036	\N	2026-09-28 08:19:32.685036	t	411	2026-09-29 07:02:15.429	20	1
131	2026-09-28	14	3858	\N	\N	60	1586.400	submitted	Iftikhar Ahmed	2026-09-28 08:20:47.446165	\N	2026-09-28 08:20:47.446165	t	411	2026-09-29 07:02:15.429	20	1
130	2026-09-28	14	3857	\N	\N	3	91.400	submitted	Iftikhar Ahmed	2026-09-28 08:20:10.572634	Tahir Hassan	2026-09-28 20:08:38.959	t	411	2026-09-29 07:02:15.429	20	1
132	2026-09-28	14	3859	\N	\N	4	123.750	submitted	Iftikhar Ahmed	2026-09-28 08:21:21.090251	Tahir Hassan	2026-09-28 20:08:45.553	t	411	2026-09-29 07:02:15.429	20	1
152	2026-10-07	16	3874	\N	\N	4	104.950	submitted	Iftikhar Ahmed	2026-10-07 09:11:04.487742	\N	2026-10-07 09:11:04.487742	t	438	2026-10-09 07:17:47.817	23	1
153	2026-10-07	16	3875	\N	\N	60	1652.550	submitted	Iftikhar Ahmed	2026-10-07 12:10:51.698659	\N	2026-10-07 12:10:51.698659	t	438	2026-10-09 07:17:47.817	20	1
154	2026-10-07	16	3876	\N	\N	32	857.150	submitted	Iftikhar Ahmed	2026-10-07 12:53:54.675053	\N	2026-10-07 12:53:54.675053	t	438	2026-10-09 07:17:47.817	20	1
155	2026-10-07	16	3876	\N	\N	15	407.850	submitted	Iftikhar Ahmed	2026-10-07 12:54:39.759977	\N	2026-10-07 12:54:39.759977	t	438	2026-10-09 07:17:47.817	23	1
156	2026-10-08	16	3877	\N	\N	3	72.100	submitted	Iftikhar Ahmed	2026-10-08 07:24:41.607238	\N	2026-10-08 07:24:41.607238	t	439	2026-10-09 07:18:58.877	23	1
157	2026-10-08	16	3878	\N	\N	60	1716.950	submitted	Iftikhar Ahmed	2026-10-09 07:24:36.792518	\N	2026-10-09 07:24:36.792518	t	440	2026-10-09 07:29:10.674	20	1
158	2026-10-08	16	3879	\N	\N	28	784.250	submitted	Iftikhar Ahmed	2026-10-09 07:26:01.728433	\N	2026-10-09 07:26:01.728433	t	440	2026-10-09 07:29:10.674	20	1
159	2026-10-08	16	3879	\N	\N	17	406.600	submitted	Iftikhar Ahmed	2026-10-09 07:26:51.516829	\N	2026-10-09 07:26:51.516829	t	440	2026-10-09 07:29:10.674	23	1
160	2026-10-09	16	3880	\N	\N	47	1203.900	submitted	Iftikhar Ahmed	2026-10-09 10:27:43.878642	\N	2026-10-09 10:27:43.878642	t	441	2026-10-09 12:52:48.99	20	1
161	2026-10-09	16	D-3880	\N	\N	5	140.600	submitted	Iftikhar Ahmed	2026-10-09 10:28:19.074119	\N	2026-10-09 10:28:19.074119	t	441	2026-10-09 12:52:48.99	23	1
162	2026-10-09	16	3881	\N	\N	1	21.000	submitted	Iftikhar Ahmed	2026-10-09 10:29:18.829957	\N	2026-10-09 10:29:18.829957	t	441	2026-10-09 12:52:48.99	23	1
163	2026-10-09	16	3882	\N	\N	2	45.850	submitted	Iftikhar Ahmed	2026-10-09 10:29:56.599116	\N	2026-10-09 10:29:56.599116	t	441	2026-10-09 12:52:48.99	23	1
164	2026-10-09	16	3883	\N	\N	60	1581.150	submitted	Iftikhar Ahmed	2026-10-09 14:21:29.205223	\N	2026-10-09 14:21:29.205223	t	443	2026-10-10 07:12:16.795	20	1
165	2026-10-09	16	3884	\N	\N	33	919.400	submitted	Iftikhar Ahmed	2026-10-09 14:22:35.663777	\N	2026-10-09 14:22:35.663777	t	443	2026-10-10 07:12:16.795	20	1
166	2026-10-09	16	3884	\N	\N	17	401.350	submitted	Iftikhar Ahmed	2026-10-09 14:23:28.468807	\N	2026-10-09 14:23:28.468807	t	443	2026-10-10 07:12:16.795	23	1
167	2026-10-10	16	3885	\N	\N	11	305.550	submitted	Iftikhar Ahmed	2026-10-10 11:01:45.525035	\N	2026-10-10 11:01:45.525035	t	449	2026-10-12 07:26:22.77	20	1
168	2026-10-12	16	3887	\N	\N	60	1632.450	submitted	Iftikhar Ahmed	2026-10-12 15:40:44.207658	\N	2026-10-12 15:40:44.207658	t	453	2026-10-13 06:57:47.104	20	1
169	2026-10-12	16	3888	\N	\N	33	873.050	submitted	Iftikhar Ahmed	2026-10-12 15:41:22.806925	\N	2026-10-12 15:41:22.806925	t	453	2026-10-13 06:57:47.104	20	1
170	2026-10-12	16	3889	\N	\N	39	1008.500	submitted	Iftikhar Ahmed	2026-10-12 15:42:03.491155	\N	2026-10-12 15:42:03.491155	t	453	2026-10-13 06:57:47.104	20	1
171	2026-10-12	16	3889	\N	\N	8	185.200	submitted	Iftikhar Ahmed	2026-10-12 15:42:46.192778	\N	2026-10-12 15:42:46.192778	t	453	2026-10-13 06:57:47.104	23	1
172	2026-10-12	16	3890	\N	\N	21	516.800	submitted	Iftikhar Ahmed	2026-10-12 15:43:21.706491	\N	2026-10-12 15:43:21.706491	t	453	2026-10-13 06:57:47.104	22	1
173	2026-10-13	16	3891	\N	\N	49	1308.500	submitted	Iftikhar Ahmed	2026-10-13 08:18:57.987403	\N	2026-10-13 08:18:57.987403	t	461	2026-10-14 09:58:59.687	20	1
174	2026-10-13	16	3891	\N	\N	8	190.150	submitted	Iftikhar Ahmed	2026-10-13 08:19:33.544616	\N	2026-10-13 08:19:33.544616	t	461	2026-10-14 09:58:59.687	23	1
177	2026-10-13	16	3894	\N	\N	26	745.400	submitted	Iftikhar Ahmed	2026-10-13 13:46:01.150322	\N	2026-10-13 13:46:01.150322	t	461	2026-10-14 09:58:59.687	20	1
178	2026-10-13	16	3894	\N	\N	9	208.450	submitted	Iftikhar Ahmed	2026-10-13 13:46:54.509879	\N	2026-10-13 13:46:54.509879	t	461	2026-10-14 09:58:59.687	23	1
175	2026-10-13	14	3892	\N	\N	60	1720.400	submitted	Iftikhar Ahmed	2026-10-13 10:13:54.885956	\N	2026-10-13 10:13:54.885956	t	462	2026-10-14 11:12:46.071	20	1
176	2026-10-13	14	3893	\N	\N	2	48.550	submitted	Iftikhar Ahmed	2026-10-13 10:14:37.179639	\N	2026-10-13 10:14:37.179639	t	462	2026-10-14 11:12:46.071	20	1
179	2026-10-14	21	3895	\N	\N	14	303.350	submitted	Iftikhar Ahmed	2026-10-14 08:08:19.394613	\N	2026-10-14 08:08:19.394613	t	463	2026-10-14 11:15:33.181	24	1
180	2026-10-14	16	3896	\N	\N	28	753.050	submitted	Iftikhar Ahmed	2026-10-14 11:32:23.599481	\N	2026-10-14 11:32:23.599481	t	467	2026-10-15 06:58:10.986	20	1
181	2026-10-14	16	3897	\N	\N	27	751.500	submitted	Iftikhar Ahmed	2026-10-14 11:33:03.757641	\N	2026-10-14 11:33:03.757641	t	467	2026-10-15 06:58:10.986	20	1
182	2026-10-15	14	3898	\N	\N	60	1761.700	submitted	Iftikhar Ahmed	2026-10-15 07:47:54.483563	\N	2026-10-15 07:47:54.483563	t	470	2026-10-15 11:12:09.315	20	1
183	2026-10-15	16	3899	\N	\N	27	759.450	submitted	Iftikhar Ahmed	2026-10-15 13:43:06.878933	\N	2026-10-15 13:43:06.878933	t	473	2026-10-16 05:46:58.132	20	1
185	2026-10-15	16	3900	\N	\N	1	10.800	submitted	Iftikhar Ahmed	2026-10-16 06:01:36.917398	\N	2026-10-16 06:01:36.917398	t	474	2026-10-16 06:41:46.067	30	1
186	2026-10-16	14	3901	\N	\N	51	1468.200	submitted	Iftikhar Ahmed	2026-10-16 07:36:27.356802	\N	2026-10-16 07:36:27.356802	t	478	2026-10-16 09:49:31.739	20	1
187	2026-10-16	21	1487	\N	\N	15	332.650	submitted	Iftikhar Ahmed	2026-10-16 07:58:35.463711	\N	2026-10-16 07:58:35.463711	t	479	2026-10-16 09:50:26.677	24	1
188	2026-10-17	16	3905	\N	\N	31	706.150	submitted	Iftikhar Ahmed	2026-10-17 09:58:38.633248	\N	2026-10-17 09:58:38.633248	t	486	2026-10-19 06:55:35.554	20	1
189	2026-10-17	16	3904	\N	\N	27	700.750	submitted	Iftikhar Ahmed	2026-10-17 09:59:13.477022	\N	2026-10-17 09:59:13.477022	t	486	2026-10-19 06:55:35.554	20	1
190	2026-10-19	14	3906	\N	\N	51	1407.700	submitted	Iftikhar Ahmed	2026-10-19 07:09:23.365736	\N	2026-10-19 07:09:23.365736	t	494	2026-10-19 09:59:58.15	20	1
191	2026-10-19	14	D-3907	\N	\N	51	1404.150	submitted	Iftikhar Ahmed	2026-10-19 07:09:59.023183	\N	2026-10-19 07:09:59.023183	t	494	2026-10-19 09:59:58.15	20	1
192	2026-10-19	21	3908	\N	\N	19	419.100	submitted	Iftikhar Ahmed	2026-10-19 07:10:43.900495	\N	2026-10-19 07:10:43.900495	t	495	2026-10-19 10:01:01.777	24	1
193	2026-10-19	14	D-3909	\N	\N	54	1412.050	submitted	Iftikhar Ahmed	2026-10-20 06:52:56.220385	\N	2026-10-20 06:52:56.220385	t	502	2026-10-20 07:16:11.104	20	1
194	2026-10-19	16	3911	\N	\N	60	1401.550	submitted	Iftikhar Ahmed	2026-10-20 06:54:53.943169	\N	2026-10-20 06:54:53.943169	t	503	2026-10-20 07:17:37.19	20	1
195	2026-10-19	17	3913	\N	\N	21	630.100	submitted	Iftikhar Ahmed	2026-10-20 06:55:54.084733	\N	2026-10-20 06:55:54.084733	t	504	2026-10-20 07:19:00.108	20	1
198	2026-10-21	16	3916	\N	\N	22	543.000	submitted	Iftikhar Ahmed	2026-10-21 05:25:35.732461	\N	2026-10-21 05:25:35.732461	t	507	2026-10-21 06:15:36.937	20	1
196	2026-10-20	14	3914	\N	\N	50	1402.500	submitted	Iftikhar Ahmed	2026-10-20 09:18:13.203669	\N	2026-10-20 09:18:13.203669	t	508	2026-10-21 06:26:51.371	20	1
197	2026-10-20	16	3915	\N	\N	34	754.450	submitted	Iftikhar Ahmed	2026-10-20 11:00:26.022141	\N	2026-10-20 11:00:26.022141	t	509	2026-10-21 06:28:42.291	20	1
199	2026-10-21	21	1488	\N	\N	15	339.450	submitted	Iftikhar Ahmed	2026-10-21 07:05:51.037105	Khurram Hassan	2026-10-21 09:59:03.301	t	517	2026-10-21 09:59:54.377	24	1
200	2026-10-21	16	3917	\N	\N	31	746.700	submitted	Iftikhar Ahmed	2026-10-21 08:09:36.625556	\N	2026-10-21 08:09:36.625556	t	518	2026-10-21 10:04:06.648	20	1
201	2026-10-21	16	3918	\N	\N	14	362.000	submitted	Iftikhar Ahmed	2026-10-21 08:10:10.042494	\N	2026-10-21 08:10:10.042494	t	518	2026-10-21 10:04:06.648	20	1
202	2026-10-21	14	3919	\N	\N	49	1404.950	submitted	Iftikhar Ahmed	2026-10-21 09:48:41.755129	\N	2026-10-21 09:48:41.755129	t	519	2026-10-21 10:05:56.932	20	1
203	2026-10-22	14	3920	\N	\N	51	1412.800	submitted	Iftikhar Ahmed	2026-10-22 09:18:24.58649	\N	2026-10-22 09:18:24.58649	t	529	2026-10-23 07:40:01.402	20	1
204	2026-10-22	16	3921	\N	\N	29	746.150	submitted	Iftikhar Ahmed	2026-10-22 13:23:20.799266	Khurram Hassan	2026-10-23 07:40:27.818	t	530	2026-10-23 07:43:28.197	20	1
205	2026-10-23	14	3922	\N	\N	51	1410.150	submitted	Iftikhar Ahmed	2026-10-23 07:12:11.535846	\N	2026-10-23 07:12:11.535846	t	531	2026-10-23 07:46:35.676	20	1
206	2026-10-24	14	3924	\N	\N	49	1407.500	submitted	Iftikhar Ahmed	2026-10-24 06:35:09.538495	\N	2026-10-24 06:35:09.538495	t	537	2026-10-24 09:14:45.191	20	1
207	2026-10-24	14	3925	\N	\N	32	761.400	submitted	Iftikhar Ahmed	2026-10-24 14:03:27.91801	\N	2026-10-24 14:03:27.91801	f	\N	\N	20	1
208	2026-10-26	14	3926	\N	\N	60	1703.600	submitted	Iftikhar Ahmed	2026-10-26 12:49:07.1436	\N	2026-10-26 12:49:07.1436	f	\N	\N	20	1
209	2026-10-26	14	3927	\N	\N	8	221.700	submitted	Iftikhar Ahmed	2026-10-26 12:49:54.511563	\N	2026-10-26 12:49:54.511563	f	\N	\N	20	1
210	2026-10-26	14	3928	\N	\N	51	1411.450	submitted	Iftikhar Ahmed	2026-10-26 12:50:38.009345	\N	2026-10-26 12:50:38.009345	f	\N	\N	20	1
211	2026-10-26	17	3930	\N	\N	25	720.250	submitted	Iftikhar Ahmed	2026-10-26 12:54:57.522792	\N	2026-10-26 12:54:57.522792	f	\N	\N	20	1
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
4621	666	1	25.500	\N	2026-10-12 06:08:39.50614	1
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
4622	666	2	24.550	\N	2026-10-12 06:08:39.50614	1
4623	666	3	31.250	\N	2026-10-12 06:08:39.50614	1
4624	666	4	31.900	\N	2026-10-12 06:08:39.50614	1
4625	666	5	31.500	\N	2026-10-12 06:08:39.50614	1
4626	666	6	30.450	\N	2026-10-12 06:08:39.50614	1
4627	666	7	31.800	\N	2026-10-12 06:08:39.50614	1
4628	667	1	24.650	\N	2026-10-12 06:09:22.087376	1
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
1887	262	1	26.050	\N	2026-08-30 06:29:46.255071	1
1888	262	2	28.250	\N	2026-08-30 06:29:46.255071	1
1889	262	3	28.200	\N	2026-08-30 06:29:46.255071	1
1890	262	4	28.000	\N	2026-08-30 06:29:46.255071	1
1891	262	5	29.450	\N	2026-08-30 06:29:46.255071	1
1892	262	6	26.950	\N	2026-08-30 06:29:46.255071	1
1893	262	7	27.850	\N	2026-08-30 06:29:46.255071	1
1894	262	8	29.700	\N	2026-08-30 06:29:46.255071	1
1895	263	1	29.200	\N	2026-08-30 06:31:19.933643	1
1896	263	2	29.500	\N	2026-08-30 06:31:19.933643	1
1897	263	3	29.200	\N	2026-08-30 06:31:19.933643	1
1898	263	4	28.100	\N	2026-08-30 06:31:19.933643	1
1899	263	5	28.900	\N	2026-08-30 06:31:19.933643	1
1900	263	6	27.900	\N	2026-08-30 06:31:19.933643	1
1901	263	7	32.250	\N	2026-08-30 06:31:19.933643	1
1902	264	1	16.800	\N	2026-08-30 06:33:10.395894	1
1903	264	2	18.400	\N	2026-08-30 06:33:10.395894	1
1904	264	3	23.500	\N	2026-08-30 06:33:10.395894	1
1905	264	4	15.150	\N	2026-08-30 06:33:10.395894	1
1906	265	1	12.150	\N	2026-08-30 06:34:09.320377	1
1907	265	2	27.700	\N	2026-08-30 06:34:09.320377	1
1908	265	3	26.200	\N	2026-08-30 06:34:09.320377	1
1909	265	4	22.500	\N	2026-08-30 06:34:09.320377	1
1910	266	1	27.800	\N	2026-08-30 06:35:27.52574	1
1911	266	2	27.400	\N	2026-08-30 06:35:27.52574	1
1912	266	3	27.100	\N	2026-08-30 06:35:27.52574	1
1913	266	4	28.950	\N	2026-08-30 06:35:27.52574	1
1914	266	5	27.700	\N	2026-08-30 06:35:27.52574	1
1915	266	6	27.050	\N	2026-08-30 06:35:27.52574	1
1916	266	7	29.300	\N	2026-08-30 06:35:27.52574	1
1917	267	1	27.500	\N	2026-08-30 06:36:16.470087	1
1918	267	2	26.800	\N	2026-08-30 06:36:16.470087	1
1919	267	3	16.450	\N	2026-08-30 06:36:16.470087	1
1920	267	4	27.500	\N	2026-08-30 06:36:16.470087	1
1921	267	5	30.450	\N	2026-08-30 06:36:16.470087	1
1922	268	1	17.500	\N	2026-08-30 06:37:46.079886	1
1923	268	2	25.950	\N	2026-08-30 06:37:46.079886	1
1924	268	3	24.600	\N	2026-08-30 06:37:46.079886	1
1925	268	4	26.700	\N	2026-08-30 06:37:46.079886	1
1926	268	5	26.550	\N	2026-08-30 06:37:46.079886	1
1927	268	6	27.800	\N	2026-08-30 06:37:46.079886	1
1928	269	1	27.100	\N	2026-08-30 06:38:55.251152	1
1929	269	2	26.400	\N	2026-08-30 06:38:55.251152	1
1930	269	3	26.550	\N	2026-08-30 06:38:55.251152	1
1931	269	4	28.800	\N	2026-08-30 06:38:55.251152	1
1932	269	5	27.500	\N	2026-08-30 06:38:55.251152	1
1933	269	6	21.650	\N	2026-08-30 06:38:55.251152	1
1934	270	1	26.350	\N	2026-08-31 06:05:03.286897	1
1935	270	2	26.300	\N	2026-08-31 06:05:03.286897	1
1936	270	3	26.150	\N	2026-08-31 06:05:03.286897	1
1937	270	4	27.100	\N	2026-08-31 06:05:03.286897	1
1938	270	5	18.650	\N	2026-08-31 06:05:03.286897	1
1939	270	6	26.150	\N	2026-08-31 06:05:03.286897	1
1940	271	1	28.450	\N	2026-08-31 06:05:46.504167	1
1941	271	2	27.550	\N	2026-08-31 06:05:46.504167	1
1942	271	3	25.100	\N	2026-08-31 06:05:46.504167	1
1943	271	4	24.750	\N	2026-08-31 06:05:46.504167	1
1944	271	5	30.550	\N	2026-08-31 06:05:46.504167	1
4629	667	2	31.650	\N	2026-10-12 06:09:22.087376	1
4630	667	3	26.950	\N	2026-10-12 06:09:22.087376	1
4631	667	4	29.900	\N	2026-10-12 06:09:22.087376	1
4632	667	5	32.250	\N	2026-10-12 06:09:22.087376	1
4633	667	6	30.650	\N	2026-10-12 06:09:22.087376	1
4634	667	7	32.600	\N	2026-10-12 06:09:22.087376	1
4635	668	1	31.250	\N	2026-10-12 06:09:59.475116	1
4636	668	2	29.500	\N	2026-10-12 06:09:59.475116	1
4637	668	3	28.050	\N	2026-10-12 06:09:59.475116	1
1954	273	1	25.550	\N	2026-08-31 06:08:31.230185	1
1955	273	2	27.550	\N	2026-08-31 06:08:31.230185	1
1956	274	1	21.500	\N	2026-08-31 06:09:11.963016	1
1957	274	2	28.550	\N	2026-08-31 06:09:11.963016	1
1958	274	3	24.750	\N	2026-08-31 06:09:11.963016	1
1959	274	4	26.900	\N	2026-08-31 06:09:11.963016	1
1960	272	1	17.800	\N	2026-08-31 06:10:05.882915	1
1961	272	2	25.600	\N	2026-08-31 06:10:05.882915	1
1962	272	3	26.400	\N	2026-08-31 06:10:05.882915	1
1963	272	4	27.200	\N	2026-08-31 06:10:05.882915	1
1964	272	5	23.700	\N	2026-08-31 06:10:05.882915	1
1965	272	6	26.650	\N	2026-08-31 06:10:05.882915	1
1966	272	7	27.500	\N	2026-08-31 06:10:05.882915	1
1967	272	8	24.650	\N	2026-08-31 06:10:05.882915	1
1968	272	9	26.000	\N	2026-08-31 06:10:05.882915	1
1969	275	1	24.300	\N	2026-09-01 04:44:26.933026	1
1970	276	1	25.950	\N	2026-09-01 04:45:42.937632	1
1971	276	2	21.650	\N	2026-09-01 04:45:42.937632	1
1972	276	3	25.100	\N	2026-09-01 04:45:42.937632	1
1973	276	4	18.050	\N	2026-09-01 04:45:42.937632	1
1974	276	5	26.150	\N	2026-09-01 04:45:42.937632	1
1975	276	6	26.100	\N	2026-09-01 04:45:42.937632	1
1976	276	7	16.650	\N	2026-09-01 04:45:42.937632	1
1977	276	8	26.400	\N	2026-09-01 04:45:42.937632	1
1978	277	1	25.650	\N	2026-09-01 04:46:34.663547	1
1979	277	2	26.700	\N	2026-09-01 04:46:34.663547	1
1980	277	3	26.700	\N	2026-09-01 04:46:34.663547	1
1981	277	4	26.100	\N	2026-09-01 04:46:34.663547	1
1982	277	5	27.350	\N	2026-09-01 04:46:34.663547	1
1983	277	6	13.450	\N	2026-09-01 04:46:34.663547	1
1984	277	7	25.550	\N	2026-09-01 04:46:34.663547	1
1985	278	1	32.050	\N	2026-09-01 04:48:18.618291	1
1986	278	2	23.250	\N	2026-09-01 04:48:18.618291	1
1987	279	1	26.750	\N	2026-09-01 04:49:05.856891	1
1988	279	2	13.750	\N	2026-09-01 04:49:05.856891	1
1989	279	3	26.950	\N	2026-09-01 04:49:05.856891	1
1990	279	4	24.450	\N	2026-09-01 04:49:05.856891	1
1991	279	5	26.550	\N	2026-09-01 04:49:05.856891	1
1992	279	6	26.500	\N	2026-09-01 04:49:05.856891	1
1993	279	7	27.000	\N	2026-09-01 04:49:05.856891	1
1994	279	8	26.850	\N	2026-09-01 04:49:05.856891	1
1995	280	1	27.450	\N	2026-09-01 04:49:53.24394	1
1996	280	2	24.600	\N	2026-09-01 04:49:53.24394	1
1997	280	3	25.450	\N	2026-09-01 04:49:53.24394	1
1998	280	4	24.600	\N	2026-09-01 04:49:53.24394	1
1999	280	5	26.700	\N	2026-09-01 04:49:53.24394	1
2000	280	6	25.400	\N	2026-09-01 04:49:53.24394	1
2001	280	7	25.450	\N	2026-09-01 04:49:53.24394	1
2002	281	1	23.550	\N	2026-09-02 04:50:38.735469	1
2003	281	2	27.050	\N	2026-09-02 04:50:38.735469	1
2004	281	3	29.000	\N	2026-09-02 04:50:38.735469	1
2005	281	4	24.300	\N	2026-09-02 04:50:38.735469	1
2006	281	5	23.950	\N	2026-09-02 04:50:38.735469	1
2007	281	6	29.900	\N	2026-09-02 04:50:38.735469	1
2008	281	7	28.950	\N	2026-09-02 04:50:38.735469	1
2009	282	1	26.100	\N	2026-09-02 04:51:29.028617	1
2010	282	2	23.850	\N	2026-09-02 04:51:29.028617	1
2011	282	3	21.300	\N	2026-09-02 04:51:29.028617	1
2012	282	4	26.200	\N	2026-09-02 04:51:29.028617	1
2013	282	5	28.800	\N	2026-09-02 04:51:29.028617	1
2014	282	6	24.250	\N	2026-09-02 04:51:29.028617	1
2015	282	7	26.600	\N	2026-09-02 04:51:29.028617	1
2016	283	1	26.350	\N	2026-09-02 04:52:25.524808	1
2017	283	2	25.500	\N	2026-09-02 04:52:25.524808	1
2018	283	3	25.750	\N	2026-09-02 04:52:25.524808	1
2019	283	4	24.300	\N	2026-09-02 04:52:25.524808	1
2020	283	5	26.700	\N	2026-09-02 04:52:25.524808	1
2021	283	6	26.500	\N	2026-09-02 04:52:25.524808	1
2022	283	7	17.850	\N	2026-09-02 04:52:25.524808	1
2023	283	8	24.400	\N	2026-09-02 04:52:25.524808	1
2024	284	1	23.750	\N	2026-09-02 04:53:08.528273	1
2025	284	2	24.550	\N	2026-09-02 04:53:08.528273	1
2026	284	3	21.100	\N	2026-09-02 04:53:08.528273	1
2027	284	4	27.100	\N	2026-09-02 04:53:08.528273	1
2028	284	5	26.050	\N	2026-09-02 04:53:08.528273	1
2029	284	6	23.900	\N	2026-09-02 04:53:08.528273	1
2030	285	1	33.200	\N	2026-09-02 04:53:57.073478	1
2031	285	2	24.250	\N	2026-09-02 04:53:57.073478	1
2032	285	3	26.150	\N	2026-09-02 04:53:57.073478	1
2033	285	4	27.650	\N	2026-09-02 04:53:57.073478	1
2034	285	5	26.200	\N	2026-09-02 04:53:57.073478	1
2035	285	6	30.300	\N	2026-09-02 04:53:57.073478	1
2036	285	7	24.900	\N	2026-09-02 04:53:57.073478	1
2037	285	8	24.650	\N	2026-09-02 04:53:57.073478	1
2038	286	1	25.350	\N	2026-09-02 04:54:40.171174	1
2039	286	2	25.300	\N	2026-09-02 04:54:40.171174	1
2040	286	3	24.400	\N	2026-09-02 04:54:40.171174	1
2041	286	4	24.600	\N	2026-09-02 04:54:40.171174	1
2042	286	5	25.700	\N	2026-09-02 04:54:40.171174	1
2043	286	6	25.150	\N	2026-09-02 04:54:40.171174	1
2044	286	7	27.800	\N	2026-09-02 04:54:40.171174	1
2045	287	1	20.250	\N	2026-09-03 04:52:19.158718	1
2046	288	1	22.800	\N	2026-09-03 04:52:58.725231	1
2047	289	1	27.500	\N	2026-09-03 04:55:45.238487	1
2048	289	2	27.100	\N	2026-09-03 04:55:45.238487	1
2049	289	3	30.450	\N	2026-09-03 04:55:45.238487	1
2050	289	4	27.600	\N	2026-09-03 04:55:45.238487	1
2051	289	5	24.550	\N	2026-09-03 04:55:45.238487	1
2052	289	6	27.200	\N	2026-09-03 04:55:45.238487	1
2053	289	7	24.600	\N	2026-09-03 04:55:45.238487	1
2054	290	1	27.150	\N	2026-09-03 04:56:32.635688	1
2055	290	2	24.200	\N	2026-09-03 04:56:32.635688	1
2056	290	3	25.550	\N	2026-09-03 04:56:32.635688	1
2057	290	4	27.300	\N	2026-09-03 04:56:32.635688	1
2058	290	5	22.850	\N	2026-09-03 04:56:32.635688	1
2059	290	6	23.600	\N	2026-09-03 04:56:32.635688	1
2060	290	7	27.250	\N	2026-09-03 04:56:32.635688	1
2061	291	1	25.500	\N	2026-09-03 04:57:14.813276	1
2062	291	2	23.200	\N	2026-09-03 04:57:14.813276	1
2063	291	3	25.950	\N	2026-09-03 04:57:14.813276	1
2064	291	4	26.550	\N	2026-09-03 04:57:14.813276	1
2065	291	5	24.800	\N	2026-09-03 04:57:14.813276	1
2066	291	6	25.300	\N	2026-09-03 04:57:14.813276	1
2067	291	7	26.850	\N	2026-09-03 04:57:14.813276	1
2068	292	1	26.500	\N	2026-09-03 04:59:17.294043	1
2069	292	2	27.450	\N	2026-09-03 04:59:17.294043	1
2070	292	3	29.650	\N	2026-09-03 04:59:17.294043	1
2071	292	4	31.950	\N	2026-09-03 04:59:17.294043	1
2072	292	5	26.500	\N	2026-09-03 04:59:17.294043	1
2073	292	6	29.750	\N	2026-09-03 04:59:17.294043	1
2074	292	7	28.650	\N	2026-09-03 04:59:17.294043	1
2075	292	8	30.300	\N	2026-09-03 04:59:17.294043	1
2076	293	1	29.300	\N	2026-09-03 05:00:07.629471	1
2077	293	2	21.100	\N	2026-09-03 05:00:07.629471	1
2078	293	3	31.050	\N	2026-09-03 05:00:07.629471	1
2079	293	4	29.400	\N	2026-09-03 05:00:07.629471	1
2080	293	5	30.750	\N	2026-09-03 05:00:07.629471	1
2081	293	6	28.350	\N	2026-09-03 05:00:07.629471	1
2082	293	7	27.250	\N	2026-09-03 05:00:07.629471	1
2083	293	8	30.600	\N	2026-09-03 05:00:07.629471	1
2084	294	1	23.500	\N	2026-09-03 05:01:09.399441	1
2085	294	2	24.750	\N	2026-09-03 05:01:09.399441	1
2086	294	3	23.150	\N	2026-09-03 05:01:09.399441	1
2087	294	4	19.300	\N	2026-09-03 05:01:09.399441	1
2088	294	5	24.400	\N	2026-09-03 05:01:09.399441	1
2089	294	6	22.900	\N	2026-09-03 05:01:09.399441	1
2090	294	7	19.900	\N	2026-09-03 05:01:09.399441	1
2091	295	1	20.550	\N	2026-09-03 05:02:08.12926	1
2092	295	2	27.750	\N	2026-09-03 05:02:08.12926	1
2093	295	3	27.400	\N	2026-09-03 05:02:08.12926	1
2094	295	4	27.900	\N	2026-09-03 05:02:08.12926	1
2095	295	5	25.550	\N	2026-09-03 05:02:08.12926	1
2096	295	6	24.950	\N	2026-09-03 05:02:08.12926	1
2097	295	7	25.250	\N	2026-09-03 05:02:08.12926	1
2098	295	8	30.350	\N	2026-09-03 05:02:08.12926	1
2099	296	1	18.100	\N	2026-09-03 05:02:54.157023	1
2100	296	2	26.100	\N	2026-09-03 05:02:54.157023	1
2101	296	3	25.100	\N	2026-09-03 05:02:54.157023	1
2102	296	4	27.350	\N	2026-09-03 05:02:54.157023	1
2103	296	5	30.400	\N	2026-09-03 05:02:54.157023	1
2104	296	6	26.150	\N	2026-09-03 05:02:54.157023	1
2105	297	1	25.350	\N	2026-09-03 05:03:39.558044	1
2106	297	2	25.450	\N	2026-09-03 05:03:39.558044	1
2107	297	3	26.900	\N	2026-09-03 05:03:39.558044	1
2108	297	4	24.250	\N	2026-09-03 05:03:39.558044	1
2109	297	5	23.650	\N	2026-09-03 05:03:39.558044	1
2110	297	6	24.300	\N	2026-09-03 05:03:39.558044	1
2111	297	7	31.950	\N	2026-09-03 05:03:39.558044	1
2112	298	1	29.400	\N	2026-09-03 15:23:36.962888	1
2113	298	2	28.950	\N	2026-09-03 15:23:36.962888	1
2114	298	3	28.100	\N	2026-09-03 15:23:36.962888	1
2115	298	4	27.650	\N	2026-09-03 15:23:36.962888	1
2116	298	5	24.850	\N	2026-09-03 15:23:36.962888	1
2117	299	1	29.050	\N	2026-09-03 15:24:10.972002	1
2118	299	2	29.100	\N	2026-09-03 15:24:10.972002	1
2119	299	3	33.400	\N	2026-09-03 15:24:10.972002	1
2120	299	4	32.500	\N	2026-09-03 15:24:10.972002	1
2121	300	1	30.300	\N	2026-09-03 15:25:39.080157	1
2122	300	2	30.100	\N	2026-09-03 15:25:39.080157	1
2123	300	3	29.150	\N	2026-09-03 15:25:39.080157	1
2124	300	4	30.350	\N	2026-09-03 15:25:39.080157	1
2125	300	5	30.200	\N	2026-09-03 15:25:39.080157	1
2126	300	6	30.800	\N	2026-09-03 15:25:39.080157	1
2127	300	7	30.050	\N	2026-09-03 15:25:39.080157	1
2128	300	8	28.700	\N	2026-09-03 15:25:39.080157	1
2129	300	9	28.400	\N	2026-09-03 15:25:39.080157	1
2130	300	10	29.500	\N	2026-09-03 15:25:39.080157	1
2131	301	1	30.550	\N	2026-09-03 15:28:41.509102	1
2132	301	2	27.850	\N	2026-09-03 15:28:41.509102	1
2133	301	3	27.300	\N	2026-09-03 15:28:41.509102	1
2134	301	4	26.850	\N	2026-09-03 15:28:41.509102	1
2135	301	5	31.300	\N	2026-09-03 15:28:41.509102	1
2136	301	6	27.900	\N	2026-09-03 15:28:41.509102	1
2137	301	7	28.300	\N	2026-09-03 15:28:41.509102	1
2138	301	8	28.650	\N	2026-09-03 15:28:41.509102	1
2139	301	9	29.000	\N	2026-09-03 15:28:41.509102	1
2140	301	10	31.600	\N	2026-09-03 15:28:41.509102	1
2141	302	1	22.150	\N	2026-09-03 15:29:21.926945	1
2142	302	2	18.900	\N	2026-09-03 15:29:21.926945	1
2143	302	3	20.750	\N	2026-09-03 15:29:21.926945	1
2144	302	4	18.050	\N	2026-09-03 15:29:21.926945	1
2145	302	5	20.050	\N	2026-09-03 15:29:21.926945	1
2146	302	6	12.250	\N	2026-09-03 15:29:21.926945	1
2147	303	1	22.550	\N	2026-09-03 15:30:20.351575	1
2148	303	2	30.900	\N	2026-09-03 15:30:20.351575	1
2149	303	3	25.900	\N	2026-09-03 15:30:20.351575	1
2150	303	4	22.000	\N	2026-09-03 15:30:20.351575	1
2151	303	5	28.300	\N	2026-09-03 15:30:20.351575	1
2152	303	6	33.450	\N	2026-09-03 15:30:20.351575	1
2153	303	7	33.550	\N	2026-09-03 15:30:20.351575	1
2154	303	8	28.600	\N	2026-09-03 15:30:20.351575	1
2155	304	1	27.050	\N	2026-09-03 15:31:08.93545	1
2156	304	2	26.450	\N	2026-09-03 15:31:08.93545	1
2157	304	3	19.450	\N	2026-09-03 15:31:08.93545	1
2158	304	4	25.050	\N	2026-09-03 15:31:08.93545	1
2159	304	5	22.250	\N	2026-09-03 15:31:08.93545	1
2160	304	6	20.900	\N	2026-09-03 15:31:08.93545	1
2161	304	7	17.800	\N	2026-09-03 15:31:08.93545	1
2162	304	8	22.500	\N	2026-09-03 15:31:08.93545	1
2163	305	1	26.500	\N	2026-09-03 15:31:55.003695	1
2164	305	2	25.500	\N	2026-09-03 15:31:55.003695	1
2165	305	3	26.050	\N	2026-09-03 15:31:55.003695	1
2166	305	4	26.300	\N	2026-09-03 15:31:55.003695	1
2167	305	5	25.500	\N	2026-09-03 15:31:55.003695	1
2168	305	6	24.600	\N	2026-09-03 15:31:55.003695	1
2169	305	7	20.450	\N	2026-09-03 15:31:55.003695	1
2170	305	8	19.500	\N	2026-09-03 15:31:55.003695	1
2171	306	1	28.250	\N	2026-09-04 05:14:18.559286	1
2172	306	2	27.300	\N	2026-09-04 05:14:18.559286	1
2173	306	3	27.050	\N	2026-09-04 05:14:18.559286	1
2174	306	4	27.000	\N	2026-09-04 05:14:18.559286	1
2175	306	5	29.000	\N	2026-09-04 05:14:18.559286	1
2176	306	6	27.550	\N	2026-09-04 05:14:18.559286	1
2177	306	7	26.450	\N	2026-09-04 05:14:18.559286	1
2178	306	8	23.950	\N	2026-09-04 05:14:18.559286	1
2179	306	9	29.550	\N	2026-09-04 05:14:18.559286	1
2180	307	1	27.850	\N	2026-09-04 05:15:51.690749	1
2181	307	2	27.800	\N	2026-09-04 05:15:51.690749	1
2182	307	3	26.600	\N	2026-09-04 05:15:51.690749	1
2183	307	4	27.400	\N	2026-09-04 05:15:51.690749	1
2184	307	5	27.800	\N	2026-09-04 05:15:51.690749	1
2185	307	6	23.850	\N	2026-09-04 05:15:51.690749	1
2186	307	7	25.150	\N	2026-09-04 05:15:51.690749	1
2187	307	8	33.150	\N	2026-09-04 05:15:51.690749	1
2188	307	9	26.750	\N	2026-09-04 05:15:51.690749	1
2189	308	1	25.750	\N	2026-09-04 05:16:48.474743	1
2190	308	2	16.250	\N	2026-09-04 05:16:48.474743	1
2191	308	3	29.150	\N	2026-09-04 05:16:48.474743	1
2192	308	4	26.300	\N	2026-09-04 05:16:48.474743	1
2193	308	5	30.350	\N	2026-09-04 05:16:48.474743	1
2194	308	6	21.650	\N	2026-09-04 05:16:48.474743	1
2195	308	7	30.800	\N	2026-09-04 05:16:48.474743	1
2196	308	8	30.150	\N	2026-09-04 05:16:48.474743	1
2197	308	9	27.850	\N	2026-09-04 05:16:48.474743	1
2198	309	1	29.200	\N	2026-09-04 05:17:41.96003	1
2199	309	2	18.800	\N	2026-09-04 05:17:41.96003	1
2200	309	3	30.850	\N	2026-09-04 05:17:41.96003	1
2201	309	4	29.000	\N	2026-09-04 05:17:41.96003	1
2202	309	5	28.950	\N	2026-09-04 05:17:41.96003	1
2203	309	6	29.000	\N	2026-09-04 05:17:41.96003	1
2204	309	7	27.850	\N	2026-09-04 05:17:41.96003	1
2205	309	8	31.350	\N	2026-09-04 05:17:41.96003	1
2206	309	9	26.950	\N	2026-09-04 05:17:41.96003	1
2207	310	1	20.650	\N	2026-09-04 05:19:01.387991	1
2208	310	2	21.100	\N	2026-09-04 05:19:01.387991	1
2209	310	3	24.150	\N	2026-09-04 05:19:01.387991	1
2210	310	4	23.900	\N	2026-09-04 05:19:01.387991	1
2211	310	5	23.450	\N	2026-09-04 05:19:01.387991	1
2212	310	6	17.250	\N	2026-09-04 05:19:01.387991	1
2213	310	7	20.850	\N	2026-09-04 05:19:01.387991	1
2214	311	1	27.450	\N	2026-09-04 05:20:04.476544	1
2215	311	2	26.600	\N	2026-09-04 05:20:04.476544	1
2216	311	3	22.250	\N	2026-09-04 05:20:04.476544	1
2217	311	4	21.850	\N	2026-09-04 05:20:04.476544	1
2218	311	5	29.050	\N	2026-09-04 05:20:04.476544	1
2219	311	6	27.600	\N	2026-09-04 05:20:04.476544	1
2220	311	7	22.000	\N	2026-09-04 05:20:04.476544	1
2221	311	8	24.250	\N	2026-09-04 05:20:04.476544	1
2222	312	1	24.900	\N	2026-09-04 05:20:53.495878	1
2223	312	2	28.100	\N	2026-09-04 05:20:53.495878	1
2224	312	3	26.950	\N	2026-09-04 05:20:53.495878	1
2225	312	4	17.250	\N	2026-09-04 05:20:53.495878	1
2226	312	5	25.250	\N	2026-09-04 05:20:53.495878	1
2227	312	6	27.300	\N	2026-09-04 05:20:53.495878	1
2228	312	7	23.900	\N	2026-09-04 05:20:53.495878	1
2229	313	1	29.750	\N	2026-09-04 05:21:44.903005	1
2230	313	2	24.900	\N	2026-09-04 05:21:44.903005	1
2231	313	3	25.750	\N	2026-09-04 05:21:44.903005	1
2232	313	4	25.450	\N	2026-09-04 05:21:44.903005	1
2233	313	5	25.500	\N	2026-09-04 05:21:44.903005	1
2234	313	6	26.900	\N	2026-09-04 05:21:44.903005	1
2235	313	7	34.100	\N	2026-09-04 05:21:44.903005	1
2236	314	1	28.850	\N	2026-09-05 05:53:24.093352	1
2237	314	2	28.750	\N	2026-09-05 05:53:24.093352	1
2238	314	3	29.150	\N	2026-09-05 05:53:24.093352	1
2239	314	4	28.050	\N	2026-09-05 05:53:24.093352	1
2240	314	5	28.900	\N	2026-09-05 05:53:24.093352	1
2241	314	6	29.800	\N	2026-09-05 05:53:24.093352	1
2242	314	7	13.550	\N	2026-09-05 05:53:24.093352	1
2243	314	8	21.650	\N	2026-09-05 05:53:24.093352	1
2244	315	1	28.450	\N	2026-09-05 05:54:19.183635	1
2245	315	2	30.250	\N	2026-09-05 05:54:19.183635	1
2246	315	3	28.150	\N	2026-09-05 05:54:19.183635	1
2247	315	4	30.200	\N	2026-09-05 05:54:19.183635	1
2248	315	5	29.800	\N	2026-09-05 05:54:19.183635	1
2249	315	6	30.050	\N	2026-09-05 05:54:19.183635	1
2250	315	7	30.200	\N	2026-09-05 05:54:19.183635	1
2251	315	8	28.300	\N	2026-09-05 05:54:19.183635	1
2252	315	9	31.000	\N	2026-09-05 05:54:19.183635	1
2253	316	1	22.050	\N	2026-09-05 05:56:29.347517	1
2254	316	2	23.550	\N	2026-09-05 05:56:29.347517	1
2255	316	3	13.850	\N	2026-09-05 05:56:29.347517	1
2256	316	4	18.000	\N	2026-09-05 05:56:29.347517	1
2257	316	5	8.100	\N	2026-09-05 05:56:29.347517	1
2258	316	6	20.200	\N	2026-09-05 05:56:29.347517	1
2259	316	7	22.800	\N	2026-09-05 05:56:29.347517	1
2260	316	8	23.150	\N	2026-09-05 05:56:29.347517	1
2261	316	9	19.450	\N	2026-09-05 05:56:29.347517	1
2262	317	1	27.300	\N	2026-09-05 05:57:30.119127	1
2263	317	2	26.700	\N	2026-09-05 05:57:30.119127	1
2264	317	3	28.200	\N	2026-09-05 05:57:30.119127	1
2265	317	4	31.500	\N	2026-09-05 05:57:30.119127	1
2266	317	5	34.800	\N	2026-09-05 05:57:30.119127	1
2267	317	6	25.350	\N	2026-09-05 05:57:30.119127	1
2268	317	7	32.550	\N	2026-09-05 05:57:30.119127	1
2269	318	1	26.100	\N	2026-09-05 05:58:21.372134	1
2270	318	2	26.350	\N	2026-09-05 05:58:21.372134	1
2271	318	3	26.550	\N	2026-09-05 05:58:21.372134	1
2272	318	4	27.200	\N	2026-09-05 05:58:21.372134	1
2273	318	5	18.100	\N	2026-09-05 05:58:21.372134	1
2274	318	6	29.750	\N	2026-09-05 05:58:21.372134	1
2275	319	1	26.000	\N	2026-09-05 05:59:05.731021	1
2276	319	2	27.000	\N	2026-09-05 05:59:05.731021	1
2277	319	3	24.450	\N	2026-09-05 05:59:05.731021	1
2278	319	4	19.600	\N	2026-09-05 05:59:05.731021	1
2279	319	5	26.600	\N	2026-09-05 05:59:05.731021	1
2280	319	6	23.600	\N	2026-09-05 05:59:05.731021	1
2281	319	7	19.100	\N	2026-09-05 05:59:05.731021	1
2282	320	1	37.200	\N	2026-09-05 05:59:58.419463	1
2283	320	2	29.850	\N	2026-09-05 05:59:58.419463	1
2284	320	3	28.000	\N	2026-09-05 05:59:58.419463	1
2285	320	4	28.050	\N	2026-09-05 05:59:58.419463	1
2286	320	5	28.050	\N	2026-09-05 05:59:58.419463	1
2287	320	6	28.050	\N	2026-09-05 05:59:58.419463	1
2288	320	7	28.150	\N	2026-09-05 05:59:58.419463	1
2289	321	1	24.350	\N	2026-09-05 06:00:32.674707	1
2290	321	2	21.850	\N	2026-09-05 06:00:32.674707	1
2291	321	3	21.000	\N	2026-09-05 06:00:32.674707	1
2292	321	4	21.950	\N	2026-09-05 06:00:32.674707	1
2293	322	1	25.450	\N	2026-09-05 06:01:23.855317	1
2294	322	2	27.650	\N	2026-09-05 06:01:23.855317	1
2295	322	3	31.400	\N	2026-09-05 06:01:23.855317	1
2296	322	4	30.050	\N	2026-09-05 06:01:23.855317	1
2297	322	5	23.450	\N	2026-09-05 06:01:23.855317	1
2298	322	6	28.250	\N	2026-09-05 06:01:23.855317	1
2299	323	1	33.250	\N	2026-09-05 06:02:29.031289	1
2300	323	2	25.100	\N	2026-09-05 06:02:29.031289	1
2301	323	3	26.000	\N	2026-09-05 06:02:29.031289	1
2302	323	4	25.700	\N	2026-09-05 06:02:29.031289	1
2303	324	1	29.650	\N	2026-09-06 06:50:04.595755	1
2304	324	2	30.600	\N	2026-09-06 06:50:04.595755	1
2305	324	3	28.500	\N	2026-09-06 06:50:04.595755	1
2306	324	4	28.100	\N	2026-09-06 06:50:04.595755	1
2307	324	5	30.800	\N	2026-09-06 06:50:04.595755	1
2308	324	6	26.850	\N	2026-09-06 06:50:04.595755	1
2309	324	7	34.150	\N	2026-09-06 06:50:04.595755	1
2310	325	1	30.450	\N	2026-09-06 06:51:07.354827	1
2311	325	2	29.900	\N	2026-09-06 06:51:07.354827	1
2312	325	3	25.100	\N	2026-09-06 06:51:07.354827	1
2313	325	4	27.800	\N	2026-09-06 06:51:07.354827	1
2314	325	5	26.550	\N	2026-09-06 06:51:07.354827	1
2315	325	6	23.300	\N	2026-09-06 06:51:07.354827	1
2316	325	7	20.950	\N	2026-09-06 06:51:07.354827	1
2317	326	1	30.300	\N	2026-09-06 06:51:54.987231	1
2318	326	2	35.800	\N	2026-09-06 06:51:54.987231	1
2319	326	3	24.700	\N	2026-09-06 06:51:54.987231	1
2320	326	4	27.500	\N	2026-09-06 06:51:54.987231	1
2321	326	5	28.550	\N	2026-09-06 06:51:54.987231	1
2322	326	6	17.050	\N	2026-09-06 06:51:54.987231	1
2323	326	7	13.300	\N	2026-09-06 06:51:54.987231	1
2324	327	1	26.900	\N	2026-09-06 06:52:38.225551	1
2325	327	2	27.000	\N	2026-09-06 06:52:38.225551	1
2326	327	3	27.400	\N	2026-09-06 06:52:38.225551	1
2327	327	4	27.250	\N	2026-09-06 06:52:38.225551	1
2328	327	5	27.050	\N	2026-09-06 06:52:38.225551	1
2329	327	6	29.500	\N	2026-09-06 06:52:38.225551	1
2330	328	1	22.050	\N	2026-09-06 06:53:52.770308	1
2331	328	2	37.400	\N	2026-09-06 06:53:52.770308	1
2332	328	3	26.700	\N	2026-09-06 06:53:52.770308	1
2333	328	4	29.300	\N	2026-09-06 06:53:52.770308	1
2334	328	5	28.650	\N	2026-09-06 06:53:52.770308	1
2335	328	6	24.750	\N	2026-09-06 06:53:52.770308	1
2336	328	7	24.900	\N	2026-09-06 06:53:52.770308	1
2337	328	8	25.450	\N	2026-09-06 06:53:52.770308	1
2338	329	1	25.850	\N	2026-09-06 06:54:40.214843	1
2339	329	2	24.150	\N	2026-09-06 06:54:40.214843	1
2340	329	3	29.850	\N	2026-09-06 06:54:40.214843	1
2341	329	4	28.600	\N	2026-09-06 06:54:40.214843	1
2342	329	5	25.100	\N	2026-09-06 06:54:40.214843	1
2343	329	6	23.700	\N	2026-09-06 06:54:40.214843	1
2344	329	7	23.500	\N	2026-09-06 06:54:40.214843	1
2345	329	8	25.750	\N	2026-09-06 06:54:40.214843	1
2346	330	1	22.550	\N	2026-09-06 06:55:28.568542	1
2347	330	2	25.250	\N	2026-09-06 06:55:28.568542	1
2348	330	3	27.400	\N	2026-09-06 06:55:28.568542	1
2349	330	4	19.850	\N	2026-09-06 06:55:28.568542	1
2350	330	5	26.050	\N	2026-09-06 06:55:28.568542	1
2351	330	6	15.900	\N	2026-09-06 06:55:28.568542	1
2352	330	7	26.600	\N	2026-09-06 06:55:28.568542	1
2353	331	1	21.500	\N	2026-09-07 05:51:36.198038	1
2354	331	2	27.650	\N	2026-09-07 05:51:36.198038	1
2355	331	3	26.050	\N	2026-09-07 05:51:36.198038	1
2356	331	4	28.800	\N	2026-09-07 05:51:36.198038	1
2357	331	5	26.650	\N	2026-09-07 05:51:36.198038	1
2358	331	6	23.700	\N	2026-09-07 05:51:36.198038	1
2359	331	7	27.450	\N	2026-09-07 05:51:36.198038	1
2360	331	8	22.150	\N	2026-09-07 05:51:36.198038	1
2361	332	1	27.100	\N	2026-09-07 05:52:18.218628	1
2362	332	2	26.550	\N	2026-09-07 05:52:18.218628	1
2363	332	3	26.050	\N	2026-09-07 05:52:18.218628	1
2364	332	4	22.200	\N	2026-09-07 05:52:18.218628	1
2365	332	5	25.650	\N	2026-09-07 05:52:18.218628	1
2366	332	6	25.650	\N	2026-09-07 05:52:18.218628	1
2367	332	7	20.250	\N	2026-09-07 05:52:18.218628	1
2368	332	8	17.900	\N	2026-09-07 05:52:18.218628	1
2369	333	1	26.300	\N	2026-09-07 05:56:35.315145	1
2370	333	2	26.500	\N	2026-09-07 05:56:35.315145	1
2371	333	3	24.950	\N	2026-09-07 05:56:35.315145	1
2372	333	4	25.850	\N	2026-09-07 05:56:35.315145	1
2373	333	5	26.850	\N	2026-09-07 05:56:35.315145	1
2374	333	6	26.000	\N	2026-09-07 05:56:35.315145	1
2375	333	7	25.300	\N	2026-09-07 05:56:35.315145	1
2376	334	1	23.500	\N	2026-09-07 05:57:13.692824	1
2377	334	2	36.250	\N	2026-09-07 05:57:13.692824	1
2378	334	3	19.250	\N	2026-09-07 05:57:13.692824	1
2379	335	1	34.900	\N	2026-09-07 05:58:24.679144	1
2380	335	2	26.000	\N	2026-09-07 05:58:24.679144	1
2381	335	3	27.300	\N	2026-09-07 05:58:24.679144	1
2382	335	4	27.150	\N	2026-09-07 05:58:24.679144	1
2383	335	5	25.100	\N	2026-09-07 05:58:24.679144	1
2384	335	6	14.400	\N	2026-09-07 05:58:24.679144	1
2385	335	7	27.450	\N	2026-09-07 05:58:24.679144	1
2386	336	1	24.800	\N	2026-09-07 05:59:47.316799	1
2387	336	2	25.950	\N	2026-09-07 05:59:47.316799	1
2388	336	3	22.950	\N	2026-09-07 05:59:47.316799	1
2389	336	4	27.200	\N	2026-09-07 05:59:47.316799	1
2390	336	5	24.400	\N	2026-09-07 05:59:47.316799	1
2391	337	1	18.500	\N	2026-09-08 05:40:15.568506	1
2392	338	1	28.100	\N	2026-09-08 05:41:46.81666	1
2393	338	2	27.600	\N	2026-09-08 05:41:46.81666	1
2394	338	3	18.750	\N	2026-09-08 05:41:46.81666	1
2395	338	4	27.800	\N	2026-09-08 05:41:46.81666	1
2396	339	1	24.850	\N	2026-09-08 05:42:33.849408	1
2397	339	2	28.350	\N	2026-09-08 05:42:33.849408	1
2398	340	1	21.700	\N	2026-09-08 05:43:43.327311	1
2399	340	2	26.700	\N	2026-09-08 05:43:43.327311	1
2400	340	3	25.650	\N	2026-09-08 05:43:43.327311	1
2401	340	4	25.750	\N	2026-09-08 05:43:43.327311	1
2402	340	5	29.950	\N	2026-09-08 05:43:43.327311	1
2403	340	6	24.800	\N	2026-09-08 05:43:43.327311	1
2404	340	7	23.450	\N	2026-09-08 05:43:43.327311	1
2405	340	8	27.600	\N	2026-09-08 05:43:43.327311	1
2406	340	9	27.450	\N	2026-09-08 05:43:43.327311	1
2407	341	1	27.650	\N	2026-09-08 05:44:24.803462	1
2408	341	2	22.350	\N	2026-09-08 05:44:24.803462	1
2409	341	3	25.450	\N	2026-09-08 05:44:24.803462	1
2410	341	4	35.050	\N	2026-09-08 05:44:24.803462	1
2411	341	5	30.150	\N	2026-09-08 05:44:24.803462	1
2412	341	6	25.400	\N	2026-09-08 05:44:24.803462	1
2413	341	7	18.500	\N	2026-09-08 05:44:24.803462	1
2414	342	1	11.500	\N	2026-09-08 05:44:52.852832	1
2415	343	1	28.500	\N	2026-09-09 09:01:32.416231	1
2416	343	2	28.050	\N	2026-09-09 09:01:32.416231	1
2417	343	3	27.250	\N	2026-09-09 09:01:32.416231	1
2418	343	4	28.000	\N	2026-09-09 09:01:32.416231	1
2419	343	5	27.650	\N	2026-09-09 09:01:32.416231	1
2420	343	6	31.750	\N	2026-09-09 09:01:32.416231	1
2421	343	7	29.100	\N	2026-09-09 09:01:32.416231	1
2422	343	8	32.700	\N	2026-09-09 09:01:32.416231	1
2423	344	1	31.550	\N	2026-09-09 09:02:34.669332	1
2424	344	2	26.900	\N	2026-09-09 09:02:34.669332	1
2425	344	3	27.400	\N	2026-09-09 09:02:34.669332	1
2426	344	4	28.400	\N	2026-09-09 09:02:34.669332	1
2427	344	5	27.400	\N	2026-09-09 09:02:34.669332	1
2428	344	6	28.300	\N	2026-09-09 09:02:34.669332	1
2429	344	7	28.950	\N	2026-09-09 09:02:34.669332	1
2430	344	8	27.850	\N	2026-09-09 09:02:34.669332	1
2431	345	1	28.750	\N	2026-09-09 09:03:26.510605	1
2432	345	2	28.600	\N	2026-09-09 09:03:26.510605	1
2433	345	3	29.650	\N	2026-09-09 09:03:26.510605	1
2434	345	4	29.850	\N	2026-09-09 09:03:26.510605	1
2435	345	5	32.200	\N	2026-09-09 09:03:26.510605	1
2436	346	1	21.400	\N	2026-09-09 09:04:43.856167	1
2437	346	2	28.600	\N	2026-09-09 09:04:43.856167	1
2438	346	3	24.800	\N	2026-09-09 09:04:43.856167	1
2439	346	4	25.750	\N	2026-09-09 09:04:43.856167	1
2440	346	5	27.050	\N	2026-09-09 09:04:43.856167	1
2441	347	1	14.400	\N	2026-09-09 09:10:47.886153	1
2442	348	1	14.600	\N	2026-09-09 09:12:23.519795	1
2443	348	2	21.300	\N	2026-09-09 09:12:23.519795	1
2444	348	3	20.600	\N	2026-09-09 09:12:23.519795	1
2445	348	4	15.100	\N	2026-09-09 09:12:23.519795	1
2446	348	5	18.400	\N	2026-09-09 09:12:23.519795	1
2447	349	1	30.900	\N	2026-09-09 09:13:39.691523	1
2448	349	2	30.600	\N	2026-09-09 09:13:39.691523	1
2449	349	3	26.950	\N	2026-09-09 09:13:39.691523	1
2450	349	4	28.250	\N	2026-09-09 09:13:39.691523	1
2451	349	5	26.000	\N	2026-09-09 09:13:39.691523	1
2452	349	6	26.750	\N	2026-09-09 09:13:39.691523	1
2453	349	7	26.900	\N	2026-09-09 09:13:39.691523	1
2454	349	8	26.000	\N	2026-09-09 09:13:39.691523	1
2455	349	9	27.000	\N	2026-09-09 09:13:39.691523	1
2464	351	1	26.750	\N	2026-09-09 09:18:24.496474	1
2465	351	2	29.400	\N	2026-09-09 09:18:24.496474	1
2466	352	1	24.000	\N	2026-09-09 09:19:28.398352	1
2467	352	2	21.450	\N	2026-09-09 09:19:28.398352	1
2468	352	3	21.300	\N	2026-09-09 09:19:28.398352	1
2469	352	4	23.050	\N	2026-09-09 09:19:28.398352	1
2470	352	5	23.200	\N	2026-09-09 09:19:28.398352	1
2471	352	6	24.500	\N	2026-09-09 09:19:28.398352	1
2472	352	7	22.750	\N	2026-09-09 09:19:28.398352	1
2473	352	8	21.550	\N	2026-09-09 09:19:28.398352	1
2474	352	9	23.250	\N	2026-09-09 09:19:28.398352	1
2475	353	1	19.300	\N	2026-09-09 09:20:22.740511	1
2476	353	2	22.550	\N	2026-09-09 09:20:22.740511	1
2477	353	3	22.300	\N	2026-09-09 09:20:22.740511	1
2478	353	4	20.350	\N	2026-09-09 09:20:22.740511	1
2479	353	5	21.750	\N	2026-09-09 09:20:22.740511	1
2480	353	6	24.500	\N	2026-09-09 09:20:22.740511	1
2481	353	7	21.450	\N	2026-09-09 09:20:22.740511	1
2482	353	8	19.950	\N	2026-09-09 09:20:22.740511	1
2483	350	1	26.550	\N	2026-09-09 09:42:03.391637	1
2484	350	2	27.700	\N	2026-09-09 09:42:03.391637	1
2485	350	3	27.250	\N	2026-09-09 09:42:03.391637	1
2486	350	4	26.250	\N	2026-09-09 09:42:03.391637	1
2487	350	5	28.150	\N	2026-09-09 09:42:03.391637	1
2488	350	6	26.500	\N	2026-09-09 09:42:03.391637	1
2489	350	7	27.750	\N	2026-09-09 09:42:03.391637	1
2490	350	8	25.450	\N	2026-09-09 09:42:03.391637	1
2491	354	1	28.400	\N	2026-09-10 04:56:59.865603	1
2492	354	2	28.600	\N	2026-09-10 04:56:59.865603	1
2493	354	3	27.900	\N	2026-09-10 04:56:59.865603	1
2494	354	4	27.850	\N	2026-09-10 04:56:59.865603	1
2495	354	5	28.650	\N	2026-09-10 04:56:59.865603	1
2496	354	6	28.400	\N	2026-09-10 04:56:59.865603	1
2497	354	7	28.950	\N	2026-09-10 04:56:59.865603	1
2498	354	8	28.900	\N	2026-09-10 04:56:59.865603	1
2499	355	1	28.600	\N	2026-09-10 04:57:51.693581	1
2500	355	2	29.850	\N	2026-09-10 04:57:51.693581	1
2501	355	3	28.500	\N	2026-09-10 04:57:51.693581	1
2502	355	4	27.100	\N	2026-09-10 04:57:51.693581	1
2503	355	5	28.600	\N	2026-09-10 04:57:51.693581	1
2504	355	6	27.400	\N	2026-09-10 04:57:51.693581	1
2505	355	7	27.850	\N	2026-09-10 04:57:51.693581	1
2506	355	8	25.200	\N	2026-09-10 04:57:51.693581	1
2507	356	1	25.200	\N	2026-09-10 05:01:20.968007	1
2508	356	2	24.650	\N	2026-09-10 05:01:20.968007	1
2509	356	3	31.000	\N	2026-09-10 05:01:20.968007	1
2510	356	4	24.050	\N	2026-09-10 05:01:20.968007	1
2511	356	5	23.200	\N	2026-09-10 05:01:20.968007	1
2512	356	6	25.750	\N	2026-09-10 05:01:20.968007	1
2513	356	7	23.650	\N	2026-09-10 05:01:20.968007	1
2514	356	8	19.250	\N	2026-09-10 05:01:20.968007	1
2515	356	9	26.400	\N	2026-09-10 05:01:20.968007	1
2516	357	1	23.050	\N	2026-09-10 05:02:08.307822	1
2517	357	2	24.750	\N	2026-09-10 05:02:08.307822	1
2518	357	3	16.200	\N	2026-09-10 05:02:08.307822	1
2519	357	4	19.100	\N	2026-09-10 05:02:08.307822	1
2520	357	5	25.550	\N	2026-09-10 05:02:08.307822	1
2521	357	6	28.500	\N	2026-09-10 05:02:08.307822	1
2522	357	7	20.450	\N	2026-09-10 05:02:08.307822	1
2523	358	1	28.650	\N	2026-09-10 05:03:10.246104	1
2524	358	2	33.050	\N	2026-09-10 05:03:10.246104	1
2525	358	3	30.350	\N	2026-09-10 05:03:10.246104	1
2526	358	4	24.850	\N	2026-09-10 05:03:10.246104	1
2527	358	5	27.450	\N	2026-09-10 05:03:10.246104	1
2528	358	6	27.000	\N	2026-09-10 05:03:10.246104	1
2529	358	7	26.900	\N	2026-09-10 05:03:10.246104	1
2530	358	8	25.450	\N	2026-09-10 05:03:10.246104	1
2531	358	9	28.150	\N	2026-09-10 05:03:10.246104	1
2532	359	1	23.600	\N	2026-09-10 05:03:55.900723	1
2533	359	2	26.750	\N	2026-09-10 05:03:55.900723	1
2534	359	3	28.250	\N	2026-09-10 05:03:55.900723	1
2535	359	4	26.350	\N	2026-09-10 05:03:55.900723	1
2536	359	5	26.750	\N	2026-09-10 05:03:55.900723	1
2537	359	6	28.250	\N	2026-09-10 05:03:55.900723	1
2538	359	7	27.550	\N	2026-09-10 05:03:55.900723	1
2539	359	8	27.000	\N	2026-09-10 05:03:55.900723	1
2540	359	9	27.000	\N	2026-09-10 05:03:55.900723	1
2541	360	1	29.650	\N	2026-09-10 05:04:56.107017	1
2542	360	2	26.700	\N	2026-09-10 05:04:56.107017	1
2543	360	3	16.300	\N	2026-09-10 05:04:56.107017	1
2544	360	4	25.550	\N	2026-09-10 05:04:56.107017	1
2545	360	5	26.950	\N	2026-09-10 05:04:56.107017	1
2546	360	6	25.700	\N	2026-09-10 05:04:56.107017	1
2547	360	7	27.000	\N	2026-09-10 05:04:56.107017	1
2548	360	8	27.100	\N	2026-09-10 05:04:56.107017	1
2549	360	9	27.650	\N	2026-09-10 05:04:56.107017	1
2550	361	1	20.100	\N	2026-09-10 05:05:55.625022	1
2551	361	2	18.350	\N	2026-09-10 05:05:55.625022	1
2552	361	3	19.650	\N	2026-09-10 05:05:55.625022	1
2553	361	4	21.100	\N	2026-09-10 05:05:55.625022	1
2554	361	5	19.700	\N	2026-09-10 05:05:55.625022	1
2555	361	6	20.600	\N	2026-09-10 05:05:55.625022	1
2556	361	7	21.750	\N	2026-09-10 05:05:55.625022	1
2557	361	8	21.900	\N	2026-09-10 05:05:55.625022	1
2558	362	1	24.050	\N	2026-09-10 05:47:10.915818	1
2559	363	1	28.750	\N	2026-09-11 04:49:13.155058	1
2560	363	2	27.400	\N	2026-09-11 04:49:13.155058	1
2561	363	3	28.800	\N	2026-09-11 04:49:13.155058	1
2562	363	4	22.100	\N	2026-09-11 04:49:13.155058	1
2563	363	5	29.000	\N	2026-09-11 04:49:13.155058	1
2564	363	6	26.150	\N	2026-09-11 04:49:13.155058	1
2565	363	7	25.700	\N	2026-09-11 04:49:13.155058	1
2566	363	8	30.400	\N	2026-09-11 04:49:13.155058	1
2567	364	1	28.400	\N	2026-09-11 04:50:24.126556	1
2568	364	2	28.650	\N	2026-09-11 04:50:24.126556	1
2569	364	3	28.450	\N	2026-09-11 04:50:24.126556	1
2570	364	4	28.450	\N	2026-09-11 04:50:24.126556	1
2571	364	5	28.150	\N	2026-09-11 04:50:24.126556	1
2572	364	6	28.400	\N	2026-09-11 04:50:24.126556	1
2573	364	7	28.600	\N	2026-09-11 04:50:24.126556	1
2574	364	8	30.500	\N	2026-09-11 04:50:24.126556	1
2575	365	1	24.400	\N	2026-09-11 04:51:48.438133	1
2576	365	2	24.500	\N	2026-09-11 04:51:48.438133	1
2577	365	3	24.450	\N	2026-09-11 04:51:48.438133	1
2578	365	4	24.400	\N	2026-09-11 04:51:48.438133	1
2579	365	5	24.900	\N	2026-09-11 04:51:48.438133	1
2580	365	6	24.500	\N	2026-09-11 04:51:48.438133	1
2581	365	7	21.250	\N	2026-09-11 04:51:48.438133	1
2582	365	8	24.250	\N	2026-09-11 04:51:48.438133	1
2583	365	9	24.300	\N	2026-09-11 04:51:48.438133	1
2584	365	10	26.400	\N	2026-09-11 04:51:48.438133	1
2585	366	1	25.100	\N	2026-09-11 04:52:30.956611	1
2586	366	2	23.350	\N	2026-09-11 04:52:30.956611	1
2587	366	3	23.100	\N	2026-09-11 04:52:30.956611	1
2588	366	4	23.950	\N	2026-09-11 04:52:30.956611	1
2589	366	5	26.100	\N	2026-09-11 04:52:30.956611	1
2590	367	1	25.600	\N	2026-09-11 04:53:37.445788	1
2591	367	2	28.350	\N	2026-09-11 04:53:37.445788	1
2592	367	3	26.950	\N	2026-09-11 04:53:37.445788	1
2593	367	4	25.500	\N	2026-09-11 04:53:37.445788	1
2594	367	5	25.550	\N	2026-09-11 04:53:37.445788	1
2595	367	6	24.700	\N	2026-09-11 04:53:37.445788	1
2596	367	7	28.300	\N	2026-09-11 04:53:37.445788	1
2597	367	8	29.450	\N	2026-09-11 04:53:37.445788	1
2598	367	9	25.550	\N	2026-09-11 04:53:37.445788	1
2599	368	1	26.950	\N	2026-09-11 04:54:40.447071	1
2600	368	2	28.200	\N	2026-09-11 04:54:40.447071	1
2601	368	3	26.900	\N	2026-09-11 04:54:40.447071	1
2602	368	4	27.150	\N	2026-09-11 04:54:40.447071	1
2603	368	5	26.700	\N	2026-09-11 04:54:40.447071	1
2604	368	6	26.850	\N	2026-09-11 04:54:40.447071	1
2605	368	7	26.950	\N	2026-09-11 04:54:40.447071	1
2606	368	8	20.200	\N	2026-09-11 04:54:40.447071	1
2607	368	9	18.200	\N	2026-09-11 04:54:40.447071	1
2608	369	1	21.400	\N	2026-09-11 04:55:37.925912	1
2609	369	2	27.250	\N	2026-09-11 04:55:37.925912	1
2610	369	3	27.850	\N	2026-09-11 04:55:37.925912	1
2611	369	4	27.650	\N	2026-09-11 04:55:37.925912	1
2612	369	5	26.600	\N	2026-09-11 04:55:37.925912	1
2613	369	6	27.650	\N	2026-09-11 04:55:37.925912	1
2614	369	7	28.800	\N	2026-09-11 04:55:37.925912	1
2615	369	8	27.400	\N	2026-09-11 04:55:37.925912	1
2616	369	9	28.700	\N	2026-09-11 04:55:37.925912	1
2617	370	1	17.850	\N	2026-09-11 04:56:13.858593	1
2618	370	2	21.700	\N	2026-09-11 04:56:13.858593	1
2619	371	1	28.200	\N	2026-09-12 05:31:49.535919	1
2620	371	2	26.250	\N	2026-09-12 05:31:49.535919	1
2621	371	3	26.900	\N	2026-09-12 05:31:49.535919	1
2622	371	4	27.700	\N	2026-09-12 05:31:49.535919	1
2623	371	5	25.900	\N	2026-09-12 05:31:49.535919	1
2624	371	6	27.750	\N	2026-09-12 05:31:49.535919	1
2625	372	1	27.750	\N	2026-09-12 05:32:37.365392	1
2626	372	2	28.450	\N	2026-09-12 05:32:37.365392	1
2627	372	3	28.450	\N	2026-09-12 05:32:37.365392	1
2628	372	4	27.100	\N	2026-09-12 05:32:37.365392	1
2629	372	5	28.350	\N	2026-09-12 05:32:37.365392	1
2630	372	6	23.550	\N	2026-09-12 05:32:37.365392	1
2631	372	7	23.100	\N	2026-09-12 05:32:37.365392	1
2632	372	8	26.350	\N	2026-09-12 05:32:37.365392	1
2633	373	1	22.250	\N	2026-09-12 05:33:18.926992	1
2634	373	2	24.600	\N	2026-09-12 05:33:18.926992	1
2635	373	3	28.550	\N	2026-09-12 05:33:18.926992	1
2636	373	4	29.350	\N	2026-09-12 05:33:18.926992	1
2637	374	1	28.450	\N	2026-09-12 05:33:56.351609	1
2638	374	2	26.950	\N	2026-09-12 05:33:56.351609	1
2639	374	3	27.150	\N	2026-09-12 05:33:56.351609	1
2640	375	1	20.400	\N	2026-09-12 05:34:27.552366	1
2641	375	2	30.250	\N	2026-09-12 05:34:27.552366	1
2642	375	3	28.150	\N	2026-09-12 05:34:27.552366	1
2643	376	1	30.700	\N	2026-09-12 05:35:25.570631	1
2644	376	2	25.950	\N	2026-09-12 05:35:25.570631	1
2645	376	3	28.250	\N	2026-09-12 05:35:25.570631	1
2646	376	4	32.100	\N	2026-09-12 05:35:25.570631	1
2647	376	5	25.350	\N	2026-09-12 05:35:25.570631	1
2648	376	6	27.850	\N	2026-09-12 05:35:25.570631	1
2649	376	7	26.900	\N	2026-09-12 05:35:25.570631	1
2650	376	8	27.000	\N	2026-09-12 05:35:25.570631	1
2651	376	9	29.500	\N	2026-09-12 05:35:25.570631	1
2652	377	1	27.000	\N	2026-09-12 05:36:16.304444	1
2653	377	2	24.250	\N	2026-09-12 05:36:16.304444	1
2654	377	3	28.000	\N	2026-09-12 05:36:16.304444	1
2655	377	4	25.650	\N	2026-09-12 05:36:16.304444	1
2656	377	5	27.000	\N	2026-09-12 05:36:16.304444	1
2657	377	6	26.800	\N	2026-09-12 05:36:16.304444	1
2658	377	7	24.900	\N	2026-09-12 05:36:16.304444	1
2659	377	8	27.300	\N	2026-09-12 05:36:16.304444	1
2660	377	9	26.350	\N	2026-09-12 05:36:16.304444	1
2661	377	10	25.500	\N	2026-09-12 05:36:16.304444	1
2662	378	1	25.000	\N	2026-09-12 05:37:07.933554	1
2663	378	2	24.350	\N	2026-09-12 05:37:07.933554	1
2664	378	3	23.150	\N	2026-09-12 05:37:07.933554	1
2665	378	4	20.100	\N	2026-09-12 05:37:07.933554	1
2666	378	5	23.750	\N	2026-09-12 05:37:07.933554	1
2667	378	6	25.100	\N	2026-09-12 05:37:07.933554	1
2668	378	7	24.800	\N	2026-09-12 05:37:07.933554	1
2669	378	8	25.550	\N	2026-09-12 05:37:07.933554	1
2670	378	9	25.350	\N	2026-09-12 05:37:07.933554	1
2671	379	1	24.650	\N	2026-09-12 05:38:32.746983	1
2672	379	2	24.950	\N	2026-09-12 05:38:32.746983	1
2673	379	3	24.850	\N	2026-09-12 05:38:32.746983	1
2674	379	4	25.850	\N	2026-09-12 05:38:32.746983	1
2675	379	5	24.500	\N	2026-09-12 05:38:32.746983	1
2676	379	6	25.950	\N	2026-09-12 05:38:32.746983	1
2677	379	7	24.650	\N	2026-09-12 05:38:32.746983	1
2678	379	8	17.500	\N	2026-09-12 05:38:32.746983	1
2679	379	9	23.550	\N	2026-09-12 05:38:32.746983	1
2680	380	1	26.850	\N	2026-09-13 06:22:42.284583	1
2681	380	2	27.550	\N	2026-09-13 06:22:42.284583	1
2682	380	3	27.050	\N	2026-09-13 06:22:42.284583	1
2683	380	4	26.950	\N	2026-09-13 06:22:42.284583	1
2684	380	5	29.050	\N	2026-09-13 06:22:42.284583	1
2685	380	6	22.950	\N	2026-09-13 06:22:42.284583	1
2686	380	7	23.550	\N	2026-09-13 06:22:42.284583	1
2687	380	8	16.350	\N	2026-09-13 06:22:42.284583	1
2689	381	1	29.400	\N	2026-09-13 06:23:47.7374	1
2690	382	1	19.000	\N	2026-09-13 06:25:52.818888	1
2691	382	2	24.050	\N	2026-09-13 06:25:52.818888	1
2692	382	3	13.900	\N	2026-09-13 06:25:52.818888	1
2693	382	4	24.850	\N	2026-09-13 06:25:52.818888	1
2694	382	5	23.650	\N	2026-09-13 06:25:52.818888	1
2695	382	6	16.650	\N	2026-09-13 06:25:52.818888	1
2696	383	1	24.900	\N	2026-09-13 06:27:57.747317	1
2697	383	2	20.400	\N	2026-09-13 06:27:57.747317	1
2698	383	3	25.050	\N	2026-09-13 06:27:57.747317	1
2699	383	4	24.900	\N	2026-09-13 06:27:57.747317	1
2700	383	5	25.000	\N	2026-09-13 06:27:57.747317	1
2701	383	6	18.000	\N	2026-09-13 06:27:57.747317	1
2702	383	7	25.550	\N	2026-09-13 06:27:57.747317	1
2703	383	8	26.350	\N	2026-09-13 06:27:57.747317	1
2704	383	9	20.650	\N	2026-09-13 06:27:57.747317	1
2705	384	1	26.400	\N	2026-09-13 06:28:53.945611	1
2706	384	2	22.350	\N	2026-09-13 06:28:53.945611	1
2707	384	3	25.000	\N	2026-09-13 06:28:53.945611	1
2708	384	4	26.200	\N	2026-09-13 06:28:53.945611	1
2709	384	5	25.150	\N	2026-09-13 06:28:53.945611	1
2710	384	6	23.200	\N	2026-09-13 06:28:53.945611	1
2711	384	7	26.850	\N	2026-09-13 06:28:53.945611	1
2712	384	8	25.950	\N	2026-09-13 06:28:53.945611	1
2713	384	9	24.800	\N	2026-09-13 06:28:53.945611	1
2714	385	1	22.350	\N	2026-09-13 06:29:45.655186	1
2715	385	2	24.900	\N	2026-09-13 06:29:45.655186	1
2716	385	3	22.500	\N	2026-09-13 06:29:45.655186	1
2717	385	4	19.800	\N	2026-09-13 06:29:45.655186	1
2718	386	1	25.100	\N	2026-09-13 06:32:59.11973	1
2719	386	2	27.200	\N	2026-09-13 06:32:59.11973	1
2720	386	3	28.850	\N	2026-09-13 06:32:59.11973	1
2721	386	4	27.600	\N	2026-09-13 06:32:59.11973	1
2722	386	5	27.050	\N	2026-09-13 06:32:59.11973	1
2723	386	6	27.100	\N	2026-09-13 06:32:59.11973	1
2724	386	7	27.000	\N	2026-09-13 06:32:59.11973	1
2725	386	8	26.950	\N	2026-09-13 06:32:59.11973	1
2726	387	1	21.350	\N	2026-09-13 07:52:54.516791	1
2727	387	2	28.750	\N	2026-09-13 07:52:54.516791	1
2728	387	3	24.950	\N	2026-09-13 07:52:54.516791	1
2729	387	4	24.050	\N	2026-09-13 07:52:54.516791	1
2730	387	5	24.550	\N	2026-09-13 07:52:54.516791	1
2731	387	6	29.100	\N	2026-09-13 07:52:54.516791	1
2732	387	7	29.050	\N	2026-09-13 07:52:54.516791	1
2733	388	1	27.600	\N	2026-09-13 07:53:54.86413	1
2734	388	2	27.300	\N	2026-09-13 07:53:54.86413	1
2735	388	3	27.900	\N	2026-09-13 07:53:54.86413	1
2736	388	4	28.300	\N	2026-09-13 07:53:54.86413	1
2737	388	5	27.650	\N	2026-09-13 07:53:54.86413	1
2738	388	6	27.950	\N	2026-09-13 07:53:54.86413	1
2739	388	7	28.150	\N	2026-09-13 07:53:54.86413	1
2740	388	8	17.950	\N	2026-09-13 07:53:54.86413	1
2741	389	1	27.250	\N	2026-09-13 07:55:08.747807	1
2742	389	2	27.550	\N	2026-09-13 07:55:08.747807	1
2743	389	3	28.950	\N	2026-09-13 07:55:08.747807	1
2744	389	4	28.950	\N	2026-09-13 07:55:08.747807	1
2745	389	5	27.850	\N	2026-09-13 07:55:08.747807	1
2746	389	6	27.850	\N	2026-09-13 07:55:08.747807	1
2747	389	7	27.800	\N	2026-09-13 07:55:08.747807	1
2748	389	8	24.650	\N	2026-09-13 07:55:08.747807	1
2749	390	1	26.250	\N	2026-09-13 07:55:42.735662	1
2750	391	1	29.400	\N	2026-09-14 05:30:00.770889	1
2751	391	2	29.550	\N	2026-09-14 05:30:00.770889	1
2752	391	3	29.800	\N	2026-09-14 05:30:00.770889	1
2753	391	4	17.800	\N	2026-09-14 05:30:00.770889	1
2754	391	5	26.650	\N	2026-09-14 05:30:00.770889	1
2755	391	6	24.550	\N	2026-09-14 05:30:00.770889	1
2756	391	7	25.850	\N	2026-09-14 05:30:00.770889	1
2757	391	8	27.750	\N	2026-09-14 05:30:00.770889	1
2758	391	9	28.000	\N	2026-09-14 05:30:00.770889	1
2759	392	1	28.100	\N	2026-09-14 05:31:35.743593	1
2760	392	2	24.800	\N	2026-09-14 05:31:35.743593	1
2761	392	3	24.900	\N	2026-09-14 05:31:35.743593	1
2762	392	4	26.750	\N	2026-09-14 05:31:35.743593	1
2763	392	5	24.850	\N	2026-09-14 05:31:35.743593	1
2764	392	6	22.350	\N	2026-09-14 05:31:35.743593	1
2765	392	7	30.200	\N	2026-09-14 05:31:35.743593	1
2766	392	8	22.800	\N	2026-09-14 05:31:35.743593	1
2767	392	9	28.150	\N	2026-09-14 05:31:35.743593	1
2768	393	1	29.100	\N	2026-09-14 05:33:14.310887	1
2769	393	2	29.300	\N	2026-09-14 05:33:14.310887	1
2770	393	3	29.250	\N	2026-09-14 05:33:14.310887	1
2771	393	4	21.350	\N	2026-09-14 05:33:14.310887	1
2772	393	5	26.300	\N	2026-09-14 05:33:14.310887	1
2773	393	6	25.500	\N	2026-09-14 05:33:14.310887	1
2774	393	7	29.200	\N	2026-09-14 05:33:14.310887	1
2775	393	8	26.250	\N	2026-09-14 05:33:14.310887	1
2776	394	1	29.150	\N	2026-09-14 05:34:40.136886	1
2777	394	2	29.150	\N	2026-09-14 05:34:40.136886	1
2778	394	3	29.250	\N	2026-09-14 05:34:40.136886	1
2779	394	4	29.000	\N	2026-09-14 05:34:40.136886	1
2780	394	5	29.150	\N	2026-09-14 05:34:40.136886	1
2781	394	6	29.200	\N	2026-09-14 05:34:40.136886	1
2782	394	7	29.150	\N	2026-09-14 05:34:40.136886	1
2783	394	8	27.850	\N	2026-09-14 05:34:40.136886	1
2784	395	1	23.750	\N	2026-09-14 05:35:36.622506	1
2785	395	2	23.400	\N	2026-09-14 05:35:36.622506	1
2786	395	3	23.750	\N	2026-09-14 05:35:36.622506	1
2787	395	4	20.000	\N	2026-09-14 05:35:36.622506	1
2788	395	5	27.600	\N	2026-09-14 05:35:36.622506	1
2789	395	6	26.100	\N	2026-09-14 05:35:36.622506	1
2790	395	7	14.450	\N	2026-09-14 05:35:36.622506	1
2791	395	8	22.650	\N	2026-09-14 05:35:36.622506	1
2792	396	1	22.800	\N	2026-09-14 05:37:14.714055	1
2793	396	2	28.500	\N	2026-09-14 05:37:14.714055	1
2794	396	3	29.000	\N	2026-09-14 05:37:14.714055	1
2795	396	4	25.950	\N	2026-09-14 05:37:14.714055	1
2796	396	5	27.050	\N	2026-09-14 05:37:14.714055	1
2797	396	6	25.700	\N	2026-09-14 05:37:14.714055	1
2798	396	7	28.450	\N	2026-09-14 05:37:14.714055	1
2799	396	8	29.700	\N	2026-09-14 05:37:14.714055	1
2800	397	1	21.250	\N	2026-09-14 05:38:06.365855	1
2801	397	2	29.200	\N	2026-09-14 05:38:06.365855	1
2802	397	3	24.600	\N	2026-09-14 05:38:06.365855	1
2803	397	4	29.350	\N	2026-09-14 05:38:06.365855	1
2804	397	5	29.700	\N	2026-09-14 05:38:06.365855	1
2805	397	6	27.400	\N	2026-09-14 05:38:06.365855	1
2806	397	7	27.950	\N	2026-09-14 05:38:06.365855	1
2807	397	8	30.950	\N	2026-09-14 05:38:06.365855	1
2808	398	1	27.850	\N	2026-09-14 05:38:59.243394	1
2809	398	2	28.250	\N	2026-09-14 05:38:59.243394	1
2810	398	3	29.200	\N	2026-09-14 05:38:59.243394	1
2811	398	4	26.350	\N	2026-09-14 05:38:59.243394	1
2812	398	5	27.500	\N	2026-09-14 05:38:59.243394	1
2813	398	6	26.250	\N	2026-09-14 05:38:59.243394	1
2814	398	7	26.200	\N	2026-09-14 05:38:59.243394	1
2815	398	8	27.400	\N	2026-09-14 05:38:59.243394	1
2816	399	1	29.150	\N	2026-09-14 05:39:39.063191	1
2817	399	2	32.100	\N	2026-09-14 05:39:39.063191	1
2818	399	3	28.550	\N	2026-09-14 05:39:39.063191	1
2819	399	4	27.900	\N	2026-09-14 05:39:39.063191	1
2820	399	5	29.000	\N	2026-09-14 05:39:39.063191	1
2821	399	6	27.300	\N	2026-09-14 05:39:39.063191	1
2822	399	7	28.000	\N	2026-09-14 05:39:39.063191	1
2823	399	8	29.150	\N	2026-09-14 05:39:39.063191	1
2824	400	1	35.450	\N	2026-09-14 05:40:58.616971	1
2825	400	2	27.300	\N	2026-09-14 05:40:58.616971	1
2826	400	3	27.900	\N	2026-09-14 05:40:58.616971	1
2827	400	4	28.550	\N	2026-09-14 05:40:58.616971	1
2828	400	5	28.050	\N	2026-09-14 05:40:58.616971	1
2829	400	6	25.250	\N	2026-09-14 05:40:58.616971	1
2830	400	7	20.300	\N	2026-09-14 05:40:58.616971	1
2831	401	1	22.700	\N	2026-09-15 05:03:23.858251	1
2832	401	2	17.900	\N	2026-09-15 05:03:23.858251	1
2833	401	3	26.250	\N	2026-09-15 05:03:23.858251	1
2834	402	1	23.050	\N	2026-09-15 05:04:15.070535	1
2835	402	2	28.150	\N	2026-09-15 05:04:15.070535	1
2836	402	3	28.950	\N	2026-09-15 05:04:15.070535	1
2837	402	4	27.200	\N	2026-09-15 05:04:15.070535	1
2838	402	5	26.700	\N	2026-09-15 05:04:15.070535	1
2839	402	6	32.350	\N	2026-09-15 05:04:15.070535	1
2840	402	7	27.750	\N	2026-09-15 05:04:15.070535	1
2841	403	1	27.850	\N	2026-09-15 05:05:16.530791	1
2842	403	2	26.600	\N	2026-09-15 05:05:16.530791	1
2843	403	3	27.850	\N	2026-09-15 05:05:16.530791	1
2844	403	4	26.200	\N	2026-09-15 05:05:16.530791	1
2845	403	5	27.650	\N	2026-09-15 05:05:16.530791	1
2846	403	6	27.550	\N	2026-09-15 05:05:16.530791	1
2847	403	7	28.750	\N	2026-09-15 05:05:16.530791	1
2848	403	8	24.000	\N	2026-09-15 05:05:16.530791	1
2849	404	1	29.350	\N	2026-09-15 05:06:09.219855	1
2850	404	2	29.050	\N	2026-09-15 05:06:09.219855	1
2851	404	3	29.850	\N	2026-09-15 05:06:09.219855	1
2852	404	4	29.100	\N	2026-09-15 05:06:09.219855	1
2853	404	5	29.400	\N	2026-09-15 05:06:09.219855	1
2854	404	6	29.200	\N	2026-09-15 05:06:09.219855	1
2855	404	7	30.600	\N	2026-09-15 05:06:09.219855	1
2856	404	8	22.300	\N	2026-09-15 05:06:09.219855	1
2857	405	1	25.800	\N	2026-09-15 05:07:18.32695	1
2858	405	2	23.150	\N	2026-09-15 05:07:18.32695	1
2859	405	3	25.550	\N	2026-09-15 05:07:18.32695	1
2860	405	4	24.050	\N	2026-09-15 05:07:18.32695	1
2861	405	5	25.350	\N	2026-09-15 05:07:18.32695	1
2862	405	6	28.850	\N	2026-09-15 05:07:18.32695	1
2863	405	7	27.500	\N	2026-09-15 05:07:18.32695	1
2864	405	8	27.300	\N	2026-09-15 05:07:18.32695	1
2865	406	1	28.800	\N	2026-09-15 05:08:13.803946	1
2866	406	2	20.350	\N	2026-09-15 05:08:13.803946	1
2867	406	3	25.750	\N	2026-09-15 05:08:13.803946	1
2868	406	4	28.350	\N	2026-09-15 05:08:13.803946	1
2869	406	5	30.000	\N	2026-09-15 05:08:13.803946	1
2870	406	6	28.350	\N	2026-09-15 05:08:13.803946	1
2871	406	7	22.150	\N	2026-09-15 05:08:13.803946	1
2872	406	8	27.850	\N	2026-09-15 05:08:13.803946	1
2873	407	1	24.950	\N	2026-09-15 05:09:03.996406	1
2874	407	2	29.800	\N	2026-09-15 05:09:03.996406	1
2875	407	3	26.250	\N	2026-09-15 05:09:03.996406	1
2876	407	4	27.600	\N	2026-09-15 05:09:03.996406	1
2877	407	5	25.200	\N	2026-09-15 05:09:03.996406	1
2878	407	6	26.300	\N	2026-09-15 05:09:03.996406	1
2879	407	7	27.350	\N	2026-09-15 05:09:03.996406	1
2880	407	8	26.150	\N	2026-09-15 05:09:03.996406	1
2881	408	1	31.550	\N	2026-09-15 05:10:11.26527	1
2882	408	2	29.000	\N	2026-09-15 05:10:11.26527	1
2883	408	3	28.100	\N	2026-09-15 05:10:11.26527	1
2884	408	4	27.600	\N	2026-09-15 05:10:11.26527	1
2885	408	5	28.950	\N	2026-09-15 05:10:11.26527	1
2886	408	6	26.600	\N	2026-09-15 05:10:11.26527	1
2887	408	7	26.550	\N	2026-09-15 05:10:11.26527	1
2888	408	8	29.050	\N	2026-09-15 05:10:11.26527	1
4638	668	4	34.050	\N	2026-10-12 06:09:59.475116	1
4639	668	5	30.150	\N	2026-10-12 06:09:59.475116	1
4640	669	1	27.000	\N	2026-10-12 06:10:46.075937	1
4641	669	2	29.800	\N	2026-10-12 06:10:46.075937	1
4642	669	3	28.750	\N	2026-10-12 06:10:46.075937	1
4643	669	4	31.950	\N	2026-10-12 06:10:46.075937	1
4644	669	5	28.800	\N	2026-10-12 06:10:46.075937	1
4645	669	6	33.650	\N	2026-10-12 06:10:46.075937	1
2897	410	1	27.200	\N	2026-09-16 04:18:15.267953	1
2898	410	2	28.750	\N	2026-09-16 04:18:15.267953	1
2899	410	3	28.350	\N	2026-09-16 04:18:15.267953	1
2900	410	4	30.650	\N	2026-09-16 04:18:15.267953	1
2901	410	5	28.950	\N	2026-09-16 04:18:15.267953	1
2902	410	6	28.200	\N	2026-09-16 04:18:15.267953	1
2903	410	7	24.750	\N	2026-09-16 04:18:15.267953	1
2904	411	1	26.400	\N	2026-09-16 04:19:09.254944	1
2905	411	2	28.100	\N	2026-09-16 04:19:09.254944	1
2906	411	3	27.750	\N	2026-09-16 04:19:09.254944	1
2907	411	4	27.650	\N	2026-09-16 04:19:09.254944	1
2908	411	5	26.350	\N	2026-09-16 04:19:09.254944	1
2909	411	6	27.850	\N	2026-09-16 04:19:09.254944	1
2910	411	7	26.900	\N	2026-09-16 04:19:09.254944	1
2911	411	8	25.450	\N	2026-09-16 04:19:09.254944	1
2912	412	1	29.200	\N	2026-09-16 04:20:07.497952	1
2913	412	2	29.150	\N	2026-09-16 04:20:07.497952	1
2914	412	3	29.200	\N	2026-09-16 04:20:07.497952	1
2915	412	4	29.150	\N	2026-09-16 04:20:07.497952	1
2916	412	5	29.200	\N	2026-09-16 04:20:07.497952	1
2917	412	6	29.000	\N	2026-09-16 04:20:07.497952	1
2918	412	7	29.250	\N	2026-09-16 04:20:07.497952	1
2919	412	8	27.850	\N	2026-09-16 04:20:07.497952	1
2920	413	1	20.800	\N	2026-09-16 04:21:11.523971	1
2921	413	2	27.450	\N	2026-09-16 04:21:11.523971	1
2922	413	3	27.250	\N	2026-09-16 04:21:11.523971	1
2923	413	4	24.650	\N	2026-09-16 04:21:11.523971	1
2924	413	5	28.200	\N	2026-09-16 04:21:11.523971	1
2925	413	6	26.950	\N	2026-09-16 04:21:11.523971	1
2926	413	7	28.850	\N	2026-09-16 04:21:11.523971	1
2927	414	1	30.500	\N	2026-09-16 04:22:07.737354	1
2928	414	2	27.000	\N	2026-09-16 04:22:07.737354	1
2929	414	3	26.500	\N	2026-09-16 04:22:07.737354	1
2930	414	4	27.750	\N	2026-09-16 04:22:07.737354	1
2931	414	5	28.850	\N	2026-09-16 04:22:07.737354	1
2932	414	6	27.650	\N	2026-09-16 04:22:07.737354	1
2933	415	1	27.550	\N	2026-09-16 04:22:53.167109	1
2934	415	2	27.300	\N	2026-09-16 04:22:53.167109	1
2935	415	3	26.200	\N	2026-09-16 04:22:53.167109	1
2936	415	4	26.300	\N	2026-09-16 04:22:53.167109	1
2937	415	5	26.350	\N	2026-09-16 04:22:53.167109	1
2938	415	6	28.650	\N	2026-09-16 04:22:53.167109	1
2939	416	1	24.000	\N	2026-09-16 04:23:30.804818	1
2940	416	2	30.450	\N	2026-09-16 04:23:30.804818	1
2941	416	3	29.800	\N	2026-09-16 04:23:30.804818	1
2942	416	4	30.300	\N	2026-09-16 04:23:30.804818	1
2943	416	5	29.150	\N	2026-09-16 04:23:30.804818	1
2944	416	6	30.300	\N	2026-09-16 04:23:30.804818	1
2945	417	1	28.200	\N	2026-09-16 04:24:12.153693	1
2946	417	2	29.350	\N	2026-09-16 04:24:12.153693	1
2947	417	3	32.700	\N	2026-09-16 04:24:12.153693	1
2948	417	4	18.500	\N	2026-09-16 04:24:12.153693	1
2949	417	5	28.500	\N	2026-09-16 04:24:12.153693	1
2950	417	6	38.000	\N	2026-09-16 04:24:12.153693	1
2951	418	1	28.450	\N	2026-09-17 05:31:10.42228	1
2952	418	2	29.300	\N	2026-09-17 05:31:10.42228	1
2953	418	3	29.050	\N	2026-09-17 05:31:10.42228	1
2954	418	4	27.450	\N	2026-09-17 05:31:10.42228	1
2955	418	5	14.500	\N	2026-09-17 05:31:10.42228	1
2956	418	6	32.200	\N	2026-09-17 05:31:10.42228	1
2957	418	7	30.200	\N	2026-09-17 05:31:10.42228	1
2958	418	8	25.150	\N	2026-09-17 05:31:10.42228	1
2959	419	1	26.850	\N	2026-09-17 05:32:00.45604	1
2960	419	2	28.200	\N	2026-09-17 05:32:00.45604	1
2961	419	3	27.550	\N	2026-09-17 05:32:00.45604	1
2962	419	4	21.850	\N	2026-09-17 05:32:00.45604	1
2963	419	5	27.550	\N	2026-09-17 05:32:00.45604	1
2964	419	6	26.550	\N	2026-09-17 05:32:00.45604	1
2965	419	7	27.450	\N	2026-09-17 05:32:00.45604	1
2966	419	8	24.400	\N	2026-09-17 05:32:00.45604	1
2967	420	1	30.000	\N	2026-09-17 05:32:50.289789	1
2968	420	2	30.500	\N	2026-09-17 05:32:50.289789	1
2969	420	3	23.450	\N	2026-09-17 05:32:50.289789	1
2970	420	4	28.000	\N	2026-09-17 05:32:50.289789	1
2971	420	5	30.300	\N	2026-09-17 05:32:50.289789	1
2972	420	6	20.700	\N	2026-09-17 05:32:50.289789	1
2973	420	7	19.700	\N	2026-09-17 05:32:50.289789	1
2974	421	1	24.600	\N	2026-09-17 05:33:17.927919	1
2975	421	2	29.350	\N	2026-09-17 05:33:17.927919	1
2976	422	1	30.200	\N	2026-09-17 05:34:18.110437	1
2977	422	2	27.650	\N	2026-09-17 05:34:18.110437	1
2978	422	3	28.850	\N	2026-09-17 05:34:18.110437	1
2979	422	4	25.900	\N	2026-09-17 05:34:18.110437	1
2980	422	5	27.800	\N	2026-09-17 05:34:18.110437	1
2981	422	6	26.950	\N	2026-09-17 05:34:18.110437	1
2982	423	1	27.550	\N	2026-09-17 05:35:08.896061	1
2983	423	2	28.900	\N	2026-09-17 05:35:08.896061	1
2984	423	3	29.700	\N	2026-09-17 05:35:08.896061	1
2985	423	4	26.450	\N	2026-09-17 05:35:08.896061	1
2986	423	5	29.700	\N	2026-09-17 05:35:08.896061	1
2987	423	6	28.150	\N	2026-09-17 05:35:08.896061	1
2988	424	1	29.300	\N	2026-09-17 05:35:55.515443	1
2989	424	2	30.400	\N	2026-09-17 05:35:55.515443	1
2990	424	3	29.850	\N	2026-09-17 05:35:55.515443	1
2991	424	4	29.100	\N	2026-09-17 05:35:55.515443	1
2992	424	5	29.100	\N	2026-09-17 05:35:55.515443	1
2993	424	6	27.350	\N	2026-09-17 05:35:55.515443	1
2994	425	1	29.200	\N	2026-09-18 04:56:18.934539	1
2995	425	2	29.250	\N	2026-09-18 04:56:18.934539	1
2996	425	3	29.350	\N	2026-09-18 04:56:18.934539	1
2997	425	4	29.000	\N	2026-09-18 04:56:18.934539	1
2998	425	5	28.900	\N	2026-09-18 04:56:18.934539	1
2999	425	6	29.050	\N	2026-09-18 04:56:18.934539	1
3000	425	7	19.600	\N	2026-09-18 04:56:18.934539	1
3001	426	1	26.250	\N	2026-09-18 04:57:27.910321	1
3002	426	2	28.800	\N	2026-09-18 04:57:27.910321	1
3003	426	3	30.050	\N	2026-09-18 04:57:27.910321	1
3004	426	4	29.350	\N	2026-09-18 04:57:27.910321	1
3005	426	5	29.100	\N	2026-09-18 04:57:27.910321	1
3006	426	6	24.800	\N	2026-09-18 04:57:27.910321	1
3007	426	7	29.350	\N	2026-09-18 04:57:27.910321	1
3008	427	1	27.100	\N	2026-09-18 04:58:12.233452	1
3009	427	2	29.000	\N	2026-09-18 04:58:12.233452	1
3010	427	3	23.800	\N	2026-09-18 04:58:12.233452	1
3011	427	4	29.800	\N	2026-09-18 04:58:12.233452	1
3012	427	5	30.250	\N	2026-09-18 04:58:12.233452	1
3013	427	6	29.850	\N	2026-09-18 04:58:12.233452	1
3014	428	1	20.200	\N	2026-09-18 04:58:39.602906	1
3015	429	1	21.200	\N	2026-09-18 04:59:18.04637	1
3016	429	2	32.550	\N	2026-09-18 04:59:18.04637	1
3017	429	3	27.800	\N	2026-09-18 04:59:18.04637	1
3018	429	4	30.300	\N	2026-09-18 04:59:18.04637	1
3019	429	5	18.150	\N	2026-09-18 04:59:18.04637	1
3020	430	1	25.600	\N	2026-09-18 04:59:36.408559	1
3021	430	2	22.000	\N	2026-09-18 04:59:36.408559	1
3022	431	1	26.100	\N	2026-09-19 05:03:42.938201	1
3023	431	2	24.950	\N	2026-09-19 05:03:42.938201	1
3024	431	3	24.200	\N	2026-09-19 05:03:42.938201	1
3025	431	4	24.700	\N	2026-09-19 05:03:42.938201	1
3026	431	5	25.850	\N	2026-09-19 05:03:42.938201	1
3027	432	1	25.050	\N	2026-09-19 05:04:26.997501	1
3028	432	2	21.750	\N	2026-09-19 05:04:26.997501	1
3029	432	3	23.400	\N	2026-09-19 05:04:26.997501	1
3030	432	4	24.350	\N	2026-09-19 05:04:26.997501	1
3031	432	5	23.150	\N	2026-09-19 05:04:26.997501	1
3032	433	1	16.450	\N	2026-09-19 05:05:52.151094	1
3033	433	2	23.600	\N	2026-09-19 05:05:52.151094	1
3034	433	3	21.900	\N	2026-09-19 05:05:52.151094	1
3035	433	4	24.650	\N	2026-09-19 05:05:52.151094	1
3036	433	5	25.950	\N	2026-09-19 05:05:52.151094	1
4646	669	7	29.450	\N	2026-10-12 06:10:46.075937	1
4647	669	8	32.300	\N	2026-10-12 06:10:46.075937	1
4671	673	2	29.750	\N	2026-10-13 05:51:09.678404	1
4672	673	3	29.000	\N	2026-10-13 05:51:09.678404	1
4673	673	4	25.950	\N	2026-10-13 05:51:09.678404	1
4674	673	5	26.200	\N	2026-10-13 05:51:09.678404	1
4675	673	6	17.600	\N	2026-10-13 05:51:09.678404	1
3052	436	1	30.500	\N	2026-09-19 05:09:40.266034	1
3053	436	2	18.600	\N	2026-09-19 05:09:40.266034	1
3054	436	3	17.500	\N	2026-09-19 05:09:40.266034	1
3055	436	4	29.300	\N	2026-09-19 05:09:40.266034	1
3056	436	5	33.200	\N	2026-09-19 05:09:40.266034	1
3057	436	6	28.700	\N	2026-09-19 05:09:40.266034	1
3058	436	7	29.050	\N	2026-09-19 05:09:40.266034	1
3059	436	8	29.750	\N	2026-09-19 05:09:40.266034	1
3060	435	1	16.300	\N	2026-09-19 05:10:49.99739	1
3061	435	2	27.850	\N	2026-09-19 05:10:49.99739	1
3062	435	3	18.550	\N	2026-09-19 05:10:49.99739	1
3063	435	4	28.300	\N	2026-09-19 05:10:49.99739	1
3064	435	5	26.600	\N	2026-09-19 05:10:49.99739	1
3065	435	6	28.800	\N	2026-09-19 05:10:49.99739	1
3066	435	7	28.350	\N	2026-09-19 05:10:49.99739	1
3067	435	8	28.800	\N	2026-09-19 05:10:49.99739	1
3068	434	1	23.350	\N	2026-09-19 05:11:05.948553	1
3069	434	2	32.200	\N	2026-09-19 05:11:05.948553	1
3070	434	3	28.850	\N	2026-09-19 05:11:05.948553	1
3071	434	4	26.200	\N	2026-09-19 05:11:05.948553	1
3072	434	5	27.950	\N	2026-09-19 05:11:05.948553	1
3073	434	6	28.900	\N	2026-09-19 05:11:05.948553	1
3074	434	7	29.650	\N	2026-09-19 05:11:05.948553	1
3075	437	1	24.300	\N	2026-09-20 06:17:05.744509	1
3076	437	2	29.850	\N	2026-09-20 06:17:05.744509	1
3077	437	3	26.850	\N	2026-09-20 06:17:05.744509	1
3078	437	4	28.500	\N	2026-09-20 06:17:05.744509	1
3079	437	5	28.600	\N	2026-09-20 06:17:05.744509	1
3080	437	6	24.550	\N	2026-09-20 06:17:05.744509	1
3081	437	7	27.850	\N	2026-09-20 06:17:05.744509	1
3082	437	8	25.000	\N	2026-09-20 06:17:05.744509	1
3083	438	1	25.900	\N	2026-09-20 06:17:57.907207	1
3084	438	2	27.500	\N	2026-09-20 06:17:57.907207	1
3085	438	3	28.850	\N	2026-09-20 06:17:57.907207	1
3086	438	4	27.800	\N	2026-09-20 06:17:57.907207	1
3087	438	5	29.350	\N	2026-09-20 06:17:57.907207	1
3088	438	6	26.350	\N	2026-09-20 06:17:57.907207	1
3089	438	7	27.000	\N	2026-09-20 06:17:57.907207	1
3090	438	8	23.450	\N	2026-09-20 06:17:57.907207	1
3091	439	1	29.250	\N	2026-09-20 06:19:00.394011	1
3092	439	2	24.650	\N	2026-09-20 06:19:00.394011	1
3093	439	3	32.350	\N	2026-09-20 06:19:00.394011	1
3094	439	4	30.150	\N	2026-09-20 06:19:00.394011	1
3095	439	5	31.450	\N	2026-09-20 06:19:00.394011	1
3096	439	6	29.700	\N	2026-09-20 06:19:00.394011	1
3097	439	7	24.450	\N	2026-09-20 06:19:00.394011	1
3098	440	1	29.200	\N	2026-09-20 06:19:26.196503	1
3099	441	1	31.050	\N	2026-09-20 06:19:53.836483	1
3100	442	1	23.550	\N	2026-09-20 06:20:55.492232	1
3101	442	2	29.050	\N	2026-09-20 06:20:55.492232	1
3102	442	3	19.000	\N	2026-09-20 06:20:55.492232	1
3103	442	4	28.300	\N	2026-09-20 06:20:55.492232	1
3104	442	5	27.700	\N	2026-09-20 06:20:55.492232	1
3105	442	6	23.200	\N	2026-09-20 06:20:55.492232	1
3106	442	7	28.900	\N	2026-09-20 06:20:55.492232	1
3107	442	8	27.900	\N	2026-09-20 06:20:55.492232	1
3108	443	1	27.600	\N	2026-09-20 06:22:36.278057	1
3109	443	2	27.500	\N	2026-09-20 06:22:36.278057	1
3110	443	3	29.350	\N	2026-09-20 06:22:36.278057	1
3111	443	4	28.900	\N	2026-09-20 06:22:36.278057	1
3112	443	5	28.400	\N	2026-09-20 06:22:36.278057	1
3113	443	6	26.700	\N	2026-09-20 06:22:36.278057	1
3114	443	7	26.250	\N	2026-09-20 06:22:36.278057	1
3115	443	8	27.800	\N	2026-09-20 06:22:36.278057	1
3116	444	1	29.850	\N	2026-09-20 06:24:11.841279	1
3117	444	2	27.350	\N	2026-09-20 06:24:11.841279	1
3118	444	3	28.200	\N	2026-09-20 06:24:11.841279	1
3119	444	4	29.850	\N	2026-09-20 06:24:11.841279	1
3120	444	5	30.250	\N	2026-09-20 06:24:11.841279	1
3121	444	6	27.700	\N	2026-09-20 06:24:11.841279	1
3122	444	7	28.550	\N	2026-09-20 06:24:11.841279	1
3123	444	8	26.200	\N	2026-09-20 06:24:11.841279	1
3124	445	1	29.000	\N	2026-09-21 04:57:50.920102	1
3125	445	2	29.100	\N	2026-09-21 04:57:50.920102	1
3126	445	3	25.600	\N	2026-09-21 04:57:50.920102	1
3127	446	1	31.800	\N	2026-09-21 04:58:18.841822	1
3128	446	2	26.600	\N	2026-09-21 04:58:18.841822	1
3129	446	3	26.800	\N	2026-09-21 04:58:18.841822	1
3130	447	1	32.800	\N	2026-09-21 04:58:48.498904	1
3131	447	2	25.500	\N	2026-09-21 04:58:48.498904	1
3132	447	3	26.200	\N	2026-09-21 04:58:48.498904	1
3133	448	1	23.500	\N	2026-09-21 05:00:13.62772	1
3134	448	2	21.750	\N	2026-09-21 05:00:13.62772	1
3135	448	3	25.100	\N	2026-09-21 05:00:13.62772	1
3136	448	4	28.300	\N	2026-09-21 05:00:13.62772	1
3137	448	5	29.400	\N	2026-09-21 05:00:13.62772	1
3138	448	6	26.650	\N	2026-09-21 05:00:13.62772	1
3139	448	7	30.450	\N	2026-09-21 05:00:13.62772	1
3140	448	8	28.950	\N	2026-09-21 05:00:13.62772	1
3141	448	9	25.750	\N	2026-09-21 05:00:13.62772	1
3142	448	10	27.950	\N	2026-09-21 05:00:13.62772	1
3143	448	11	28.350	\N	2026-09-21 05:00:13.62772	1
3144	448	12	29.000	\N	2026-09-21 05:00:13.62772	1
3145	448	13	30.200	\N	2026-09-21 05:00:13.62772	1
3146	449	1	29.250	\N	2026-09-21 05:01:42.934773	1
3147	449	2	25.100	\N	2026-09-21 05:01:42.934773	1
3148	449	3	28.000	\N	2026-09-21 05:01:42.934773	1
3149	449	4	28.500	\N	2026-09-21 05:01:42.934773	1
3150	449	5	27.700	\N	2026-09-21 05:01:42.934773	1
3151	449	6	27.850	\N	2026-09-21 05:01:42.934773	1
3152	449	7	28.750	\N	2026-09-21 05:01:42.934773	1
3153	449	8	29.300	\N	2026-09-21 05:01:42.934773	1
3154	449	9	27.750	\N	2026-09-21 05:01:42.934773	1
3155	449	10	29.100	\N	2026-09-21 05:01:42.934773	1
3156	449	11	26.400	\N	2026-09-21 05:01:42.934773	1
3157	449	12	29.150	\N	2026-09-21 05:01:42.934773	1
3158	450	1	27.750	\N	2026-09-21 05:02:59.173741	1
3159	450	2	30.200	\N	2026-09-21 05:02:59.173741	1
3160	450	3	30.100	\N	2026-09-21 05:02:59.173741	1
3161	450	4	28.100	\N	2026-09-21 05:02:59.173741	1
3162	450	5	29.950	\N	2026-09-21 05:02:59.173741	1
3163	450	6	29.900	\N	2026-09-21 05:02:59.173741	1
3164	450	7	29.900	\N	2026-09-21 05:02:59.173741	1
3165	450	8	29.050	\N	2026-09-21 05:02:59.173741	1
3166	450	9	26.400	\N	2026-09-21 05:02:59.173741	1
3167	450	10	29.200	\N	2026-09-21 05:02:59.173741	1
3168	450	11	30.350	\N	2026-09-21 05:02:59.173741	1
3169	450	12	20.800	\N	2026-09-21 05:02:59.173741	1
3170	451	1	15.250	\N	2026-09-22 05:14:54.27992	1
3171	451	2	15.200	\N	2026-09-22 05:14:54.27992	1
3172	451	3	19.600	\N	2026-09-22 05:14:54.27992	1
3173	452	1	25.850	\N	2026-09-22 05:15:43.746008	1
3174	452	2	28.300	\N	2026-09-22 05:15:43.746008	1
3175	452	3	27.900	\N	2026-09-22 05:15:43.746008	1
3176	452	4	20.150	\N	2026-09-22 05:15:43.746008	1
3177	452	5	29.500	\N	2026-09-22 05:15:43.746008	1
3178	452	6	25.650	\N	2026-09-22 05:15:43.746008	1
3179	452	7	31.400	\N	2026-09-22 05:15:43.746008	1
3180	452	8	20.350	\N	2026-09-22 05:15:43.746008	1
3181	453	1	26.250	\N	2026-09-22 05:16:27.931637	1
3182	453	2	26.850	\N	2026-09-22 05:16:27.931637	1
3183	453	3	26.750	\N	2026-09-22 05:16:27.931637	1
3184	453	4	28.700	\N	2026-09-22 05:16:27.931637	1
3185	453	5	27.900	\N	2026-09-22 05:16:27.931637	1
3186	453	6	17.850	\N	2026-09-22 05:16:27.931637	1
3187	453	7	30.200	\N	2026-09-22 05:16:27.931637	1
3188	454	1	27.850	\N	2026-09-22 05:17:12.548536	1
3189	454	2	27.300	\N	2026-09-22 05:17:12.548536	1
3190	454	3	30.550	\N	2026-09-22 05:17:12.548536	1
3191	454	4	29.150	\N	2026-09-22 05:17:12.548536	1
3192	454	5	29.750	\N	2026-09-22 05:17:12.548536	1
3193	454	6	29.850	\N	2026-09-22 05:17:12.548536	1
3194	454	7	23.150	\N	2026-09-22 05:17:12.548536	1
3195	454	8	18.250	\N	2026-09-22 05:17:12.548536	1
3196	455	1	28.200	\N	2026-09-22 05:18:00.624953	1
3197	455	2	28.500	\N	2026-09-22 05:18:00.624953	1
3198	455	3	22.450	\N	2026-09-22 05:18:00.624953	1
3199	455	4	29.200	\N	2026-09-22 05:18:00.624953	1
3200	455	5	27.800	\N	2026-09-22 05:18:00.624953	1
3201	455	6	29.350	\N	2026-09-22 05:18:00.624953	1
3202	456	1	28.700	\N	2026-09-22 05:18:47.404198	1
3203	456	2	27.950	\N	2026-09-22 05:18:47.404198	1
3204	456	3	27.600	\N	2026-09-22 05:18:47.404198	1
3205	456	4	28.800	\N	2026-09-22 05:18:47.404198	1
3206	456	5	25.950	\N	2026-09-22 05:18:47.404198	1
3207	456	6	28.100	\N	2026-09-22 05:18:47.404198	1
3208	456	7	28.300	\N	2026-09-22 05:18:47.404198	1
3209	457	1	24.800	\N	2026-09-22 05:19:29.549521	1
3210	457	2	29.200	\N	2026-09-22 05:19:29.549521	1
3211	457	3	28.900	\N	2026-09-22 05:19:29.549521	1
3212	457	4	29.000	\N	2026-09-22 05:19:29.549521	1
3213	457	5	28.100	\N	2026-09-22 05:19:29.549521	1
3214	457	6	28.800	\N	2026-09-22 05:19:29.549521	1
3215	457	7	27.700	\N	2026-09-22 05:19:29.549521	1
3216	458	1	22.100	\N	2026-09-22 05:20:07.999457	1
3217	458	2	31.850	\N	2026-09-22 05:20:07.999457	1
3218	458	3	30.150	\N	2026-09-22 05:20:07.999457	1
3219	458	4	31.000	\N	2026-09-22 05:20:07.999457	1
3220	458	5	23.650	\N	2026-09-22 05:20:07.999457	1
3221	458	6	27.150	\N	2026-09-22 05:20:07.999457	1
3222	458	7	29.000	\N	2026-09-22 05:20:07.999457	1
3223	459	1	18.700	\N	2026-09-22 05:53:38.353245	1
3224	459	2	23.150	\N	2026-09-22 05:53:38.353245	1
3225	459	3	24.850	\N	2026-09-22 05:53:38.353245	1
3226	459	4	25.950	\N	2026-09-22 05:53:38.353245	1
3227	459	5	28.350	\N	2026-09-22 05:53:38.353245	1
3228	459	6	26.200	\N	2026-09-22 05:53:38.353245	1
3229	459	7	26.250	\N	2026-09-22 05:53:38.353245	1
3230	459	8	32.600	\N	2026-09-22 05:53:38.353245	1
3231	460	1	26.200	\N	2026-09-23 04:37:33.146043	1
3232	460	2	22.600	\N	2026-09-23 04:37:33.146043	1
3233	460	3	30.600	\N	2026-09-23 04:37:33.146043	1
3234	460	4	24.300	\N	2026-09-23 04:37:33.146043	1
3235	460	5	29.400	\N	2026-09-23 04:37:33.146043	1
3236	460	6	22.300	\N	2026-09-23 04:37:33.146043	1
3237	460	7	21.450	\N	2026-09-23 04:37:33.146043	1
3238	461	1	26.350	\N	2026-09-23 04:38:15.796589	1
3239	461	2	29.500	\N	2026-09-23 04:38:15.796589	1
3240	461	3	29.300	\N	2026-09-23 04:38:15.796589	1
3241	461	4	26.200	\N	2026-09-23 04:38:15.796589	1
3242	461	5	34.200	\N	2026-09-23 04:38:15.796589	1
3243	461	6	26.150	\N	2026-09-23 04:38:15.796589	1
3244	461	7	27.900	\N	2026-09-23 04:38:15.796589	1
3245	462	1	26.600	\N	2026-09-23 04:38:50.614799	1
3246	462	2	28.100	\N	2026-09-23 04:38:50.614799	1
3247	462	3	30.850	\N	2026-09-23 04:38:50.614799	1
3248	462	4	27.000	\N	2026-09-23 04:38:50.614799	1
3249	462	5	29.900	\N	2026-09-23 04:38:50.614799	1
3250	462	6	25.700	\N	2026-09-23 04:38:50.614799	1
3251	462	7	25.750	\N	2026-09-23 04:38:50.614799	1
3252	463	1	27.400	\N	2026-09-23 04:39:29.3422	1
3253	463	2	30.550	\N	2026-09-23 04:39:29.3422	1
3254	463	3	30.550	\N	2026-09-23 04:39:29.3422	1
3255	463	4	28.200	\N	2026-09-23 04:39:29.3422	1
3256	463	5	29.300	\N	2026-09-23 04:39:29.3422	1
3257	463	6	26.500	\N	2026-09-23 04:39:29.3422	1
3258	463	7	24.450	\N	2026-09-23 04:39:29.3422	1
3259	464	1	27.700	\N	2026-09-23 04:40:21.727617	1
3260	464	2	27.700	\N	2026-09-23 04:40:21.727617	1
3261	464	3	25.550	\N	2026-09-23 04:40:21.727617	1
3262	464	4	27.850	\N	2026-09-23 04:40:21.727617	1
3263	464	5	28.650	\N	2026-09-23 04:40:21.727617	1
3264	464	6	28.350	\N	2026-09-23 04:40:21.727617	1
3265	464	7	31.150	\N	2026-09-23 04:40:21.727617	1
3266	465	1	29.500	\N	2026-09-23 04:41:02.691455	1
3267	465	2	27.850	\N	2026-09-23 04:41:02.691455	1
3268	465	3	25.050	\N	2026-09-23 04:41:02.691455	1
3269	465	4	29.250	\N	2026-09-23 04:41:02.691455	1
3270	465	5	29.000	\N	2026-09-23 04:41:02.691455	1
3271	465	6	29.050	\N	2026-09-23 04:41:02.691455	1
3272	465	7	25.750	\N	2026-09-23 04:41:02.691455	1
3273	465	8	27.950	\N	2026-09-23 04:41:02.691455	1
3274	466	1	27.450	\N	2026-09-23 04:41:58.312408	1
3275	466	2	30.700	\N	2026-09-23 04:41:58.312408	1
3276	466	3	19.750	\N	2026-09-23 04:41:58.312408	1
3277	466	4	29.850	\N	2026-09-23 04:41:58.312408	1
3278	466	5	26.400	\N	2026-09-23 04:41:58.312408	1
3279	466	6	28.400	\N	2026-09-23 04:41:58.312408	1
3280	466	7	27.850	\N	2026-09-23 04:41:58.312408	1
3281	466	8	29.150	\N	2026-09-23 04:41:58.312408	1
3282	467	1	28.800	\N	2026-09-23 04:42:48.449846	1
3283	467	2	32.150	\N	2026-09-23 04:42:48.449846	1
3284	467	3	18.550	\N	2026-09-23 04:42:48.449846	1
3285	467	4	30.800	\N	2026-09-23 04:42:48.449846	1
3286	467	5	23.250	\N	2026-09-23 04:42:48.449846	1
3287	467	6	26.550	\N	2026-09-23 04:42:48.449846	1
3288	467	7	29.400	\N	2026-09-23 04:42:48.449846	1
3289	467	8	28.450	\N	2026-09-23 04:42:48.449846	1
3290	468	1	22.600	\N	2026-09-23 04:43:28.539423	1
3291	468	2	21.600	\N	2026-09-23 04:43:28.539423	1
3292	468	3	22.550	\N	2026-09-23 04:43:28.539423	1
3293	468	4	18.550	\N	2026-09-23 04:43:28.539423	1
3294	468	5	23.650	\N	2026-09-23 04:43:28.539423	1
3295	468	6	26.250	\N	2026-09-23 04:43:28.539423	1
3296	469	1	26.600	\N	2026-09-24 05:08:23.437537	1
3297	469	2	28.800	\N	2026-09-24 05:08:23.437537	1
3298	469	3	26.200	\N	2026-09-24 05:08:23.437537	1
3299	469	4	24.900	\N	2026-09-24 05:08:23.437537	1
3300	469	5	21.000	\N	2026-09-24 05:08:23.437537	1
3301	469	6	22.650	\N	2026-09-24 05:08:23.437537	1
3302	469	7	24.700	\N	2026-09-24 05:08:23.437537	1
3303	470	1	26.750	\N	2026-09-24 05:09:38.684363	1
3304	470	2	29.200	\N	2026-09-24 05:09:38.684363	1
3305	470	3	19.450	\N	2026-09-24 05:09:38.684363	1
3306	470	4	27.350	\N	2026-09-24 05:09:38.684363	1
3307	470	5	24.500	\N	2026-09-24 05:09:38.684363	1
3308	470	6	24.550	\N	2026-09-24 05:09:38.684363	1
3309	470	7	26.550	\N	2026-09-24 05:09:38.684363	1
3310	470	8	29.300	\N	2026-09-24 05:09:38.684363	1
3311	471	1	26.400	\N	2026-09-24 05:10:24.656258	1
3312	471	2	24.300	\N	2026-09-24 05:10:24.656258	1
3313	471	3	25.000	\N	2026-09-24 05:10:24.656258	1
3314	471	4	26.100	\N	2026-09-24 05:10:24.656258	1
3315	471	5	24.600	\N	2026-09-24 05:10:24.656258	1
3316	471	6	23.800	\N	2026-09-24 05:10:24.656258	1
3317	471	7	31.600	\N	2026-09-24 05:10:24.656258	1
3318	471	8	31.000	\N	2026-09-24 05:10:24.656258	1
3319	472	1	28.700	\N	2026-09-24 05:11:22.416977	1
3320	472	2	22.300	\N	2026-09-24 05:11:22.416977	1
3321	472	3	25.000	\N	2026-09-24 05:11:22.416977	1
3322	472	4	24.850	\N	2026-09-24 05:11:22.416977	1
3323	472	5	26.000	\N	2026-09-24 05:11:22.416977	1
3324	472	6	24.900	\N	2026-09-24 05:11:22.416977	1
3325	472	7	33.400	\N	2026-09-24 05:11:22.416977	1
3326	472	8	32.500	\N	2026-09-24 05:11:22.416977	1
3327	473	1	27.050	\N	2026-09-24 05:12:25.711941	1
3328	473	2	26.350	\N	2026-09-24 05:12:25.711941	1
3329	473	3	26.300	\N	2026-09-24 05:12:25.711941	1
3330	473	4	26.350	\N	2026-09-24 05:12:25.711941	1
3331	473	5	31.950	\N	2026-09-24 05:12:25.711941	1
3332	473	6	30.400	\N	2026-09-24 05:12:25.711941	1
3333	473	7	29.200	\N	2026-09-24 05:12:25.711941	1
3334	473	8	26.700	\N	2026-09-24 05:12:25.711941	1
3335	474	1	23.050	\N	2026-09-24 05:13:15.736301	1
3336	474	2	23.850	\N	2026-09-24 05:13:15.736301	1
3337	474	3	27.350	\N	2026-09-24 05:13:15.736301	1
3338	474	4	22.250	\N	2026-09-24 05:13:15.736301	1
3339	474	5	21.600	\N	2026-09-24 05:13:15.736301	1
3340	474	6	24.500	\N	2026-09-24 05:13:15.736301	1
3341	475	1	17.250	\N	2026-09-24 05:14:02.251101	1
3342	475	2	29.650	\N	2026-09-24 05:14:02.251101	1
3343	475	3	31.150	\N	2026-09-24 05:14:02.251101	1
3344	475	4	24.700	\N	2026-09-24 05:14:02.251101	1
3345	476	1	26.850	\N	2026-09-24 05:17:19.428044	1
3346	476	2	23.700	\N	2026-09-24 05:17:19.428044	1
3347	476	3	20.900	\N	2026-09-24 05:17:19.428044	1
3348	476	4	22.900	\N	2026-09-24 05:17:19.428044	1
3349	476	5	29.100	\N	2026-09-24 05:17:19.428044	1
3350	476	6	27.750	\N	2026-09-24 05:17:19.428044	1
3351	476	7	26.550	\N	2026-09-24 05:17:19.428044	1
3352	476	8	27.200	\N	2026-09-24 05:17:19.428044	1
3353	477	1	26.550	\N	2026-09-24 05:19:33.959135	1
3354	477	2	28.300	\N	2026-09-24 05:19:33.959135	1
3355	477	3	26.800	\N	2026-09-24 05:19:33.959135	1
3356	477	4	24.000	\N	2026-09-24 05:19:33.959135	1
3357	477	5	28.800	\N	2026-09-24 05:19:33.959135	1
3358	477	6	31.800	\N	2026-09-24 05:19:33.959135	1
3359	477	7	30.900	\N	2026-09-24 05:19:33.959135	1
3360	477	8	18.300	\N	2026-09-24 05:19:33.959135	1
3361	478	1	26.100	\N	2026-09-24 05:20:30.323928	1
3362	478	2	26.650	\N	2026-09-24 05:20:30.323928	1
3363	478	3	27.150	\N	2026-09-24 05:20:30.323928	1
3364	478	4	29.000	\N	2026-09-24 05:20:30.323928	1
3365	478	5	27.850	\N	2026-09-24 05:20:30.323928	1
3366	478	6	29.700	\N	2026-09-24 05:20:30.323928	1
3367	478	7	30.300	\N	2026-09-24 05:20:30.323928	1
3368	478	8	24.800	\N	2026-09-24 05:20:30.323928	1
3369	479	1	24.150	\N	2026-09-24 05:21:19.822946	1
3370	479	2	28.100	\N	2026-09-24 05:21:19.822946	1
3371	479	3	29.750	\N	2026-09-24 05:21:19.822946	1
3372	479	4	30.950	\N	2026-09-24 05:21:19.822946	1
3373	479	5	21.150	\N	2026-09-24 05:21:19.822946	1
3374	479	6	26.500	\N	2026-09-24 05:21:19.822946	1
3375	479	7	26.150	\N	2026-09-24 05:21:19.822946	1
3376	479	8	25.200	\N	2026-09-24 05:21:19.822946	1
3377	480	1	25.250	\N	2026-09-24 05:22:20.649999	1
3378	480	2	17.950	\N	2026-09-24 05:22:20.649999	1
3379	480	3	19.700	\N	2026-09-24 05:22:20.649999	1
3380	480	4	23.850	\N	2026-09-24 05:22:20.649999	1
3381	480	5	21.650	\N	2026-09-24 05:22:20.649999	1
3382	480	6	25.600	\N	2026-09-24 05:22:20.649999	1
3383	480	7	14.650	\N	2026-09-24 05:22:20.649999	1
3384	481	1	27.700	\N	2026-09-24 05:24:42.524893	1
3385	481	2	27.950	\N	2026-09-24 05:24:42.524893	1
3386	481	3	28.100	\N	2026-09-24 05:24:42.524893	1
3387	481	4	28.900	\N	2026-09-24 05:24:42.524893	1
3388	481	5	30.900	\N	2026-09-24 05:24:42.524893	1
3389	481	6	29.700	\N	2026-09-24 05:24:42.524893	1
3390	482	1	0.500	\N	2026-09-24 07:17:58.475403	1
3391	483	1	25.950	\N	2026-09-25 05:11:20.917583	1
3392	483	2	28.650	\N	2026-09-25 05:11:20.917583	1
3393	483	3	26.550	\N	2026-09-25 05:11:20.917583	1
3394	483	4	35.350	\N	2026-09-25 05:11:20.917583	1
3395	483	5	26.400	\N	2026-09-25 05:11:20.917583	1
3396	483	6	29.200	\N	2026-09-25 05:11:20.917583	1
3397	483	7	24.150	\N	2026-09-25 05:11:20.917583	1
3398	484	1	27.000	\N	2026-09-25 05:12:42.195023	1
3399	484	2	26.150	\N	2026-09-25 05:12:42.195023	1
3400	484	3	27.250	\N	2026-09-25 05:12:42.195023	1
3401	484	4	27.600	\N	2026-09-25 05:12:42.195023	1
3402	484	5	27.650	\N	2026-09-25 05:12:42.195023	1
3403	484	6	27.800	\N	2026-09-25 05:12:42.195023	1
3404	484	7	28.350	\N	2026-09-25 05:12:42.195023	1
3405	484	8	23.100	\N	2026-09-25 05:12:42.195023	1
3406	485	1	27.850	\N	2026-09-25 05:13:27.499211	1
3407	485	2	26.950	\N	2026-09-25 05:13:27.499211	1
3408	485	3	25.450	\N	2026-09-25 05:13:27.499211	1
3409	485	4	28.200	\N	2026-09-25 05:13:27.499211	1
3410	485	5	27.850	\N	2026-09-25 05:13:27.499211	1
3411	485	6	23.000	\N	2026-09-25 05:13:27.499211	1
3412	485	7	24.250	\N	2026-09-25 05:13:27.499211	1
3413	485	8	30.150	\N	2026-09-25 05:13:27.499211	1
3414	486	1	24.850	\N	2026-09-25 05:14:16.121527	1
3415	486	2	29.200	\N	2026-09-25 05:14:16.121527	1
3416	486	3	24.650	\N	2026-09-25 05:14:16.121527	1
3417	486	4	29.500	\N	2026-09-25 05:14:16.121527	1
3418	486	5	29.050	\N	2026-09-25 05:14:16.121527	1
3419	486	6	24.850	\N	2026-09-25 05:14:16.121527	1
3420	486	7	24.500	\N	2026-09-25 05:14:16.121527	1
3421	486	8	32.550	\N	2026-09-25 05:14:16.121527	1
3422	487	1	20.550	\N	2026-09-25 05:14:51.019124	1
3423	487	2	17.350	\N	2026-09-25 05:14:51.019124	1
3424	487	3	26.800	\N	2026-09-25 05:14:51.019124	1
3425	487	4	25.400	\N	2026-09-25 05:14:51.019124	1
3426	488	1	27.750	\N	2026-09-25 05:15:29.77875	1
3427	488	2	26.150	\N	2026-09-25 05:15:29.77875	1
3428	488	3	25.050	\N	2026-09-25 05:15:29.77875	1
3429	488	4	27.900	\N	2026-09-25 05:15:29.77875	1
3430	488	5	26.950	\N	2026-09-25 05:15:29.77875	1
3431	488	6	22.300	\N	2026-09-25 05:15:29.77875	1
3432	489	1	27.550	\N	2026-09-25 05:16:12.383904	1
3433	489	2	27.000	\N	2026-09-25 05:16:12.383904	1
3434	489	3	28.900	\N	2026-09-25 05:16:12.383904	1
3435	489	4	35.100	\N	2026-09-25 05:16:12.383904	1
3436	489	5	26.500	\N	2026-09-25 05:16:12.383904	1
3437	489	6	24.600	\N	2026-09-25 05:16:12.383904	1
3438	490	1	23.350	\N	2026-09-25 05:17:12.791009	1
3439	490	2	27.600	\N	2026-09-25 05:17:12.791009	1
3440	490	3	20.650	\N	2026-09-25 05:17:12.791009	1
3441	490	4	27.800	\N	2026-09-25 05:17:12.791009	1
3442	490	5	26.100	\N	2026-09-25 05:17:12.791009	1
3443	490	6	15.650	\N	2026-09-25 05:17:12.791009	1
3444	490	7	27.800	\N	2026-09-25 05:17:12.791009	1
3445	490	8	27.650	\N	2026-09-25 05:17:12.791009	1
3446	491	1	22.850	\N	2026-09-25 05:18:07.159466	1
3447	491	2	25.750	\N	2026-09-25 05:18:07.159466	1
3448	491	3	19.200	\N	2026-09-25 05:18:07.159466	1
3449	491	4	28.300	\N	2026-09-25 05:18:07.159466	1
3450	491	5	29.150	\N	2026-09-25 05:18:07.159466	1
3451	491	6	27.950	\N	2026-09-25 05:18:07.159466	1
3452	491	7	28.950	\N	2026-09-25 05:18:07.159466	1
3453	491	8	28.700	\N	2026-09-25 05:18:07.159466	1
3454	492	1	22.250	\N	2026-09-25 05:19:02.140968	1
3455	492	2	26.350	\N	2026-09-25 05:19:02.140968	1
3456	492	3	22.850	\N	2026-09-25 05:19:02.140968	1
3457	492	4	23.950	\N	2026-09-25 05:19:02.140968	1
3458	492	5	28.200	\N	2026-09-25 05:19:02.140968	1
3459	492	6	27.750	\N	2026-09-25 05:19:02.140968	1
3460	492	7	28.150	\N	2026-09-25 05:19:02.140968	1
3461	492	8	22.800	\N	2026-09-25 05:19:02.140968	1
3462	493	1	24.950	\N	2026-09-25 05:19:44.698957	1
3463	493	2	27.700	\N	2026-09-25 05:19:44.698957	1
3464	493	3	22.650	\N	2026-09-25 05:19:44.698957	1
3465	493	4	26.000	\N	2026-09-25 05:19:44.698957	1
3466	493	5	27.450	\N	2026-09-25 05:19:44.698957	1
3467	493	6	32.350	\N	2026-09-25 05:19:44.698957	1
3468	493	7	26.900	\N	2026-09-25 05:19:44.698957	1
3469	493	8	22.300	\N	2026-09-25 05:19:44.698957	1
4648	670	1	26.700	\N	2026-10-13 05:48:48.087163	1
4649	670	2	30.950	\N	2026-10-13 05:48:48.087163	1
3476	495	1	22.950	\N	2026-09-25 05:21:21.188327	1
3477	495	2	27.850	\N	2026-09-25 05:21:21.188327	1
3478	495	3	26.300	\N	2026-09-25 05:21:21.188327	1
3479	495	4	28.250	\N	2026-09-25 05:21:21.188327	1
3480	495	5	28.000	\N	2026-09-25 05:21:21.188327	1
3481	495	6	25.700	\N	2026-09-25 05:21:21.188327	1
3482	495	7	24.500	\N	2026-09-25 05:21:21.188327	1
3483	495	8	18.350	\N	2026-09-25 05:21:21.188327	1
3484	494	1	20.850	\N	2026-09-25 05:22:18.680928	1
3485	494	2	21.000	\N	2026-09-25 05:22:18.680928	1
3486	494	3	24.000	\N	2026-09-25 05:22:18.680928	1
3487	494	4	27.200	\N	2026-09-25 05:22:18.680928	1
3488	494	5	23.350	\N	2026-09-25 05:22:18.680928	1
3489	494	6	30.000	\N	2026-09-25 05:22:18.680928	1
3491	496	1	0.500	\N	2026-09-25 07:42:25.182633	1
3492	497	1	28.800	\N	2026-09-26 05:25:19.717696	1
3493	497	2	27.200	\N	2026-09-26 05:25:19.717696	1
3494	497	3	26.200	\N	2026-09-26 05:25:19.717696	1
3495	497	4	26.200	\N	2026-09-26 05:25:19.717696	1
3496	497	5	27.350	\N	2026-09-26 05:25:19.717696	1
3497	497	6	24.950	\N	2026-09-26 05:25:19.717696	1
3498	497	7	18.250	\N	2026-09-26 05:25:19.717696	1
3499	498	1	27.850	\N	2026-09-26 05:25:56.493613	1
3500	498	2	28.800	\N	2026-09-26 05:25:56.493613	1
3501	498	3	26.000	\N	2026-09-26 05:25:56.493613	1
3502	498	4	27.700	\N	2026-09-26 05:25:56.493613	1
3503	498	5	32.550	\N	2026-09-26 05:25:56.493613	1
3504	498	6	19.200	\N	2026-09-26 05:25:56.493613	1
3505	498	7	27.600	\N	2026-09-26 05:25:56.493613	1
3506	499	1	27.650	\N	2026-09-26 05:27:00.242494	1
3507	499	2	27.700	\N	2026-09-26 05:27:00.242494	1
3508	499	3	29.750	\N	2026-09-26 05:27:00.242494	1
3509	499	4	27.600	\N	2026-09-26 05:27:00.242494	1
3510	499	5	27.800	\N	2026-09-26 05:27:00.242494	1
3511	499	6	24.750	\N	2026-09-26 05:27:00.242494	1
3512	499	7	25.200	\N	2026-09-26 05:27:00.242494	1
3513	500	1	28.550	\N	2026-09-26 05:27:39.541535	1
3514	500	2	31.000	\N	2026-09-26 05:27:39.541535	1
3515	500	3	29.150	\N	2026-09-26 05:27:39.541535	1
3516	500	4	29.100	\N	2026-09-26 05:27:39.541535	1
3517	500	5	29.000	\N	2026-09-26 05:27:39.541535	1
3518	500	6	28.150	\N	2026-09-26 05:27:39.541535	1
3519	500	7	28.800	\N	2026-09-26 05:27:39.541535	1
3522	502	1	33.550	\N	2026-09-26 05:29:01.645652	1
3523	502	2	24.500	\N	2026-09-26 05:29:01.645652	1
3524	502	3	24.000	\N	2026-09-26 05:29:01.645652	1
3525	502	4	27.600	\N	2026-09-26 05:29:01.645652	1
3526	502	5	27.300	\N	2026-09-26 05:29:01.645652	1
3527	502	6	16.200	\N	2026-09-26 05:29:01.645652	1
3528	503	1	23.050	\N	2026-09-26 05:30:15.97516	1
3529	503	2	23.350	\N	2026-09-26 05:30:15.97516	1
3530	503	3	27.150	\N	2026-09-26 05:30:15.97516	1
3531	503	4	27.250	\N	2026-09-26 05:30:15.97516	1
3532	503	5	25.200	\N	2026-09-26 05:30:15.97516	1
3533	504	1	29.800	\N	2026-09-26 05:31:22.725554	1
3534	504	2	29.250	\N	2026-09-26 05:31:22.725554	1
3535	504	3	29.150	\N	2026-09-26 05:31:22.725554	1
3536	504	4	34.300	\N	2026-09-26 05:31:22.725554	1
3537	504	5	29.800	\N	2026-09-26 05:31:22.725554	1
3538	504	6	27.200	\N	2026-09-26 05:31:22.725554	1
3539	505	1	24.200	\N	2026-09-26 05:32:17.740826	1
3540	505	2	21.200	\N	2026-09-26 05:32:17.740826	1
3541	505	3	23.200	\N	2026-09-26 05:32:17.740826	1
3542	505	4	24.650	\N	2026-09-26 05:32:17.740826	1
3543	505	5	24.800	\N	2026-09-26 05:32:17.740826	1
3544	505	6	27.500	\N	2026-09-26 05:32:17.740826	1
3545	505	7	28.750	\N	2026-09-26 05:32:17.740826	1
3546	505	8	27.650	\N	2026-09-26 05:32:17.740826	1
3547	506	1	28.050	\N	2026-09-26 05:33:15.644109	1
3548	506	2	28.400	\N	2026-09-26 05:33:15.644109	1
3549	506	3	28.700	\N	2026-09-26 05:33:15.644109	1
3550	506	4	28.600	\N	2026-09-26 05:33:15.644109	1
3551	506	5	24.450	\N	2026-09-26 05:33:15.644109	1
3552	506	6	24.850	\N	2026-09-26 05:33:15.644109	1
3553	506	7	27.700	\N	2026-09-26 05:33:15.644109	1
3554	506	8	28.250	\N	2026-09-26 05:33:15.644109	1
3555	507	1	21.000	\N	2026-09-26 05:36:02.543633	1
3556	507	2	24.250	\N	2026-09-26 05:36:02.543633	1
3557	507	3	26.750	\N	2026-09-26 05:36:02.543633	1
3558	507	4	24.150	\N	2026-09-26 05:36:02.543633	1
3559	507	5	25.800	\N	2026-09-26 05:36:02.543633	1
3560	507	6	27.350	\N	2026-09-26 05:36:02.543633	1
3561	507	7	26.550	\N	2026-09-26 05:36:02.543633	1
3562	507	8	28.100	\N	2026-09-26 05:36:02.543633	1
3563	508	1	30.600	\N	2026-09-26 05:36:55.82065	1
3564	508	2	28.500	\N	2026-09-26 05:36:55.82065	1
3565	508	3	26.900	\N	2026-09-26 05:36:55.82065	1
3566	508	4	28.800	\N	2026-09-26 05:36:55.82065	1
3567	508	5	25.150	\N	2026-09-26 05:36:55.82065	1
3568	508	6	21.000	\N	2026-09-26 05:36:55.82065	1
3569	508	7	29.850	\N	2026-09-26 05:36:55.82065	1
3570	508	8	28.200	\N	2026-09-26 05:36:55.82065	1
3571	509	1	19.750	\N	2026-09-26 05:37:57.206518	1
3572	509	2	27.150	\N	2026-09-26 05:37:57.206518	1
3573	509	3	20.850	\N	2026-09-26 05:37:57.206518	1
3574	509	4	22.850	\N	2026-09-26 05:37:57.206518	1
3575	509	5	24.650	\N	2026-09-26 05:37:57.206518	1
3576	509	6	23.700	\N	2026-09-26 05:37:57.206518	1
3577	509	7	25.000	\N	2026-09-26 05:37:57.206518	1
3578	510	1	27.500	\N	2026-09-26 05:38:58.201978	1
3579	510	2	27.700	\N	2026-09-26 05:38:58.201978	1
3580	510	3	27.800	\N	2026-09-26 05:38:58.201978	1
3581	510	4	27.900	\N	2026-09-26 05:38:58.201978	1
3582	510	5	27.200	\N	2026-09-26 05:38:58.201978	1
3583	510	6	28.950	\N	2026-09-26 05:38:58.201978	1
3584	510	7	26.100	\N	2026-09-26 05:38:58.201978	1
3585	510	8	29.050	\N	2026-09-26 05:38:58.201978	1
3586	501	1	26.800	\N	2026-09-26 05:40:06.298519	1
3587	501	2	21.350	\N	2026-09-26 05:40:06.298519	1
3588	511	1	27.350	\N	2026-09-27 10:19:55.59282	1
3589	511	2	28.500	\N	2026-09-27 10:19:55.59282	1
3590	511	3	26.750	\N	2026-09-27 10:19:55.59282	1
3591	511	4	27.700	\N	2026-09-27 10:19:55.59282	1
3592	511	5	25.950	\N	2026-09-27 10:19:55.59282	1
3593	511	6	31.800	\N	2026-09-27 10:19:55.59282	1
3594	511	7	25.550	\N	2026-09-27 10:19:55.59282	1
3595	512	1	27.400	\N	2026-09-27 10:20:53.488316	1
3596	512	2	28.950	\N	2026-09-27 10:20:53.488316	1
3597	512	3	26.900	\N	2026-09-27 10:20:53.488316	1
3598	512	4	31.000	\N	2026-09-27 10:20:53.488316	1
3599	512	5	27.450	\N	2026-09-27 10:20:53.488316	1
3600	512	6	25.200	\N	2026-09-27 10:20:53.488316	1
3601	512	7	24.200	\N	2026-09-27 10:20:53.488316	1
3602	512	8	23.150	\N	2026-09-27 10:20:53.488316	1
3603	513	1	21.650	\N	2026-09-27 10:21:44.95564	1
3604	513	2	27.350	\N	2026-09-27 10:21:44.95564	1
3605	513	3	22.750	\N	2026-09-27 10:21:44.95564	1
3606	513	4	27.500	\N	2026-09-27 10:21:44.95564	1
3607	513	5	27.600	\N	2026-09-27 10:21:44.95564	1
3608	513	6	21.850	\N	2026-09-27 10:21:44.95564	1
3609	513	7	24.350	\N	2026-09-27 10:21:44.95564	1
3610	514	1	27.200	\N	2026-09-27 10:22:25.41471	1
3611	514	2	29.300	\N	2026-09-27 10:22:25.41471	1
3612	514	3	29.100	\N	2026-09-27 10:22:25.41471	1
3613	514	4	28.300	\N	2026-09-27 10:22:25.41471	1
3614	514	5	32.000	\N	2026-09-27 10:22:25.41471	1
3615	515	1	21.000	\N	2026-09-27 10:22:46.189125	1
3616	515	2	27.350	\N	2026-09-27 10:22:46.189125	1
3617	516	1	22.350	\N	2026-09-27 10:23:39.164147	1
3618	516	2	21.400	\N	2026-09-27 10:23:39.164147	1
3619	516	3	23.700	\N	2026-09-27 10:23:39.164147	1
3620	516	4	21.950	\N	2026-09-27 10:23:39.164147	1
3621	516	5	22.300	\N	2026-09-27 10:23:39.164147	1
3622	516	6	22.300	\N	2026-09-27 10:23:39.164147	1
3623	516	7	18.850	\N	2026-09-27 10:23:39.164147	1
3624	517	1	29.000	\N	2026-09-27 10:24:29.521687	1
3625	517	2	28.900	\N	2026-09-27 10:24:29.521687	1
3626	517	3	23.950	\N	2026-09-27 10:24:29.521687	1
3627	517	4	29.350	\N	2026-09-27 10:24:29.521687	1
3628	517	5	18.900	\N	2026-09-27 10:24:29.521687	1
3629	517	6	22.300	\N	2026-09-27 10:24:29.521687	1
3630	518	1	25.850	\N	2026-09-27 10:26:25.865741	1
3631	518	2	24.800	\N	2026-09-27 10:26:25.865741	1
3632	518	3	29.200	\N	2026-09-27 10:26:25.865741	1
3633	518	4	25.900	\N	2026-09-27 10:26:25.865741	1
3634	518	5	28.350	\N	2026-09-27 10:26:25.865741	1
3635	518	6	25.450	\N	2026-09-27 10:26:25.865741	1
3636	518	7	19.300	\N	2026-09-27 10:26:25.865741	1
3637	519	1	27.800	\N	2026-09-27 10:27:22.450215	1
3638	519	2	24.500	\N	2026-09-27 10:27:22.450215	1
3639	519	3	29.950	\N	2026-09-27 10:27:22.450215	1
3640	519	4	28.300	\N	2026-09-27 10:27:22.450215	1
3641	519	5	27.600	\N	2026-09-27 10:27:22.450215	1
3642	519	6	28.650	\N	2026-09-27 10:27:22.450215	1
3643	519	7	25.050	\N	2026-09-27 10:27:22.450215	1
3644	520	1	16.000	\N	2026-09-27 10:27:46.90704	1
3645	521	1	27.050	\N	2026-09-27 10:28:41.836799	1
3646	521	2	29.100	\N	2026-09-27 10:28:41.836799	1
3647	521	3	26.650	\N	2026-09-27 10:28:41.836799	1
3648	521	4	26.200	\N	2026-09-27 10:28:41.836799	1
3649	521	5	21.250	\N	2026-09-27 10:28:41.836799	1
3650	521	6	28.650	\N	2026-09-27 10:28:41.836799	1
3651	521	7	29.100	\N	2026-09-27 10:28:41.836799	1
3652	521	8	27.000	\N	2026-09-27 10:28:41.836799	1
3653	522	1	22.450	\N	2026-09-27 10:29:39.74333	1
3654	522	2	22.700	\N	2026-09-27 10:29:39.74333	1
3655	522	3	20.800	\N	2026-09-27 10:29:39.74333	1
3656	522	4	25.800	\N	2026-09-27 10:29:39.74333	1
3657	522	5	22.850	\N	2026-09-27 10:29:39.74333	1
3658	522	6	21.400	\N	2026-09-27 10:29:39.74333	1
3659	522	7	22.400	\N	2026-09-27 10:29:39.74333	1
3660	522	8	18.200	\N	2026-09-27 10:29:39.74333	1
3661	523	1	26.450	\N	2026-09-27 10:30:21.337081	1
3662	523	2	23.900	\N	2026-09-27 10:30:21.337081	1
3663	523	3	24.450	\N	2026-09-27 10:30:21.337081	1
3664	523	4	28.450	\N	2026-09-27 10:30:21.337081	1
3665	523	5	25.000	\N	2026-09-27 10:30:21.337081	1
3666	524	1	25.850	\N	2026-09-27 10:31:21.224684	1
3667	524	2	22.700	\N	2026-09-27 10:31:21.224684	1
3668	524	3	30.050	\N	2026-09-27 10:31:21.224684	1
3669	524	4	10.650	\N	2026-09-27 10:31:21.224684	1
3670	524	5	26.900	\N	2026-09-27 10:31:21.224684	1
3671	524	6	20.500	\N	2026-09-27 10:31:21.224684	1
3672	524	7	26.950	\N	2026-09-27 10:31:21.224684	1
3673	525	1	29.100	\N	2026-09-27 10:32:12.721474	1
3674	525	2	28.050	\N	2026-09-27 10:32:12.721474	1
3675	525	3	24.350	\N	2026-09-27 10:32:12.721474	1
3676	525	4	27.550	\N	2026-09-27 10:32:12.721474	1
3677	525	5	28.200	\N	2026-09-27 10:32:12.721474	1
3678	525	6	23.550	\N	2026-09-27 10:32:12.721474	1
3679	525	7	22.850	\N	2026-09-27 10:32:12.721474	1
3680	526	1	20.100	\N	2026-09-28 07:56:15.068036	1
3681	526	2	26.850	\N	2026-09-28 07:56:15.068036	1
3682	526	3	33.150	\N	2026-09-28 07:56:15.068036	1
3683	526	4	35.800	\N	2026-09-28 07:56:15.068036	1
3684	527	1	27.750	\N	2026-09-28 07:57:51.464605	1
3685	527	2	30.900	\N	2026-09-28 07:57:51.464605	1
3686	527	3	29.150	\N	2026-09-28 07:57:51.464605	1
3687	527	4	32.850	\N	2026-09-28 07:57:51.464605	1
3688	527	5	35.350	\N	2026-09-28 07:57:51.464605	1
3689	527	6	28.700	\N	2026-09-28 07:57:51.464605	1
3690	527	7	32.450	\N	2026-09-28 07:57:51.464605	1
3691	528	1	26.850	\N	2026-09-28 07:58:38.666462	1
3692	528	2	29.350	\N	2026-09-28 07:58:38.666462	1
3693	528	3	31.500	\N	2026-09-28 07:58:38.666462	1
3694	528	4	23.050	\N	2026-09-28 07:58:38.666462	1
3695	528	5	27.500	\N	2026-09-28 07:58:38.666462	1
3696	528	6	20.300	\N	2026-09-28 07:58:38.666462	1
3697	528	7	30.500	\N	2026-09-28 07:58:38.666462	1
3698	529	1	29.650	\N	2026-09-28 07:59:37.895976	1
3699	529	2	19.900	\N	2026-09-28 07:59:37.895976	1
3700	529	3	28.900	\N	2026-09-28 07:59:37.895976	1
3701	529	4	28.900	\N	2026-09-28 07:59:37.895976	1
3702	529	5	32.800	\N	2026-09-28 07:59:37.895976	1
3703	530	1	29.350	\N	2026-09-28 08:00:21.684671	1
3704	530	2	26.000	\N	2026-09-28 08:00:21.684671	1
3705	530	3	27.400	\N	2026-09-28 08:00:21.684671	1
3706	530	4	23.050	\N	2026-09-28 08:00:21.684671	1
3707	530	5	24.500	\N	2026-09-28 08:00:21.684671	1
3708	530	6	26.350	\N	2026-09-28 08:00:21.684671	1
3709	530	7	30.000	\N	2026-09-28 08:00:21.684671	1
3710	531	1	28.650	\N	2026-09-28 08:01:18.391712	1
3711	531	2	30.300	\N	2026-09-28 08:01:18.391712	1
3712	531	3	25.800	\N	2026-09-28 08:01:18.391712	1
3713	531	4	29.900	\N	2026-09-28 08:01:18.391712	1
3714	531	5	28.800	\N	2026-09-28 08:01:18.391712	1
3715	531	6	31.400	\N	2026-09-28 08:01:18.391712	1
3716	532	1	30.150	\N	2026-09-28 08:02:20.263414	1
3717	532	2	28.550	\N	2026-09-28 08:02:20.263414	1
3718	532	3	27.500	\N	2026-09-28 08:02:20.263414	1
3719	532	4	27.150	\N	2026-09-28 08:02:20.263414	1
3720	532	5	23.350	\N	2026-09-28 08:02:20.263414	1
3721	532	6	20.650	\N	2026-09-28 08:02:20.263414	1
3722	532	7	26.500	\N	2026-09-28 08:02:20.263414	1
3723	532	8	21.500	\N	2026-09-28 08:02:20.263414	1
3724	533	1	21.100	\N	2026-09-28 08:03:15.840225	1
3725	533	2	29.250	\N	2026-09-28 08:03:15.840225	1
3726	533	3	24.650	\N	2026-09-28 08:03:15.840225	1
3727	533	4	29.900	\N	2026-09-28 08:03:15.840225	1
3728	533	5	26.650	\N	2026-09-28 08:03:15.840225	1
3729	533	6	28.500	\N	2026-09-28 08:03:15.840225	1
3730	533	7	32.300	\N	2026-09-28 08:03:15.840225	1
3731	533	8	31.350	\N	2026-09-28 08:03:15.840225	1
3732	534	1	21.150	\N	2026-09-28 08:05:24.41467	1
3733	534	2	29.200	\N	2026-09-28 08:05:24.41467	1
3734	534	3	14.150	\N	2026-09-28 08:05:24.41467	1
3735	534	4	14.000	\N	2026-09-28 08:05:24.41467	1
3736	534	5	24.350	\N	2026-09-28 08:05:24.41467	1
3737	534	6	23.750	\N	2026-09-28 08:05:24.41467	1
3738	534	7	18.250	\N	2026-09-28 08:05:24.41467	1
3739	534	8	24.450	\N	2026-09-28 08:05:24.41467	1
3740	534	9	33.050	\N	2026-09-28 08:05:24.41467	1
3741	535	1	14.650	\N	2026-09-28 08:06:17.823147	1
3742	535	2	17.050	\N	2026-09-28 08:06:17.823147	1
3743	535	3	25.800	\N	2026-09-28 08:06:17.823147	1
3744	535	4	29.650	\N	2026-09-28 08:06:17.823147	1
3745	535	5	23.450	\N	2026-09-28 08:06:17.823147	1
3746	535	6	26.800	\N	2026-09-28 08:06:17.823147	1
3747	536	1	24.650	\N	2026-09-28 08:07:06.799973	1
3748	536	2	27.600	\N	2026-09-28 08:07:06.799973	1
3749	536	3	24.200	\N	2026-09-28 08:07:06.799973	1
3750	536	4	26.550	\N	2026-09-28 08:07:06.799973	1
3751	536	5	25.450	\N	2026-09-28 08:07:06.799973	1
3752	536	6	29.250	\N	2026-09-28 08:07:06.799973	1
3753	536	7	26.200	\N	2026-09-28 08:07:06.799973	1
3754	537	1	24.250	\N	2026-09-28 08:08:11.863295	1
3755	537	2	28.900	\N	2026-09-28 08:08:11.863295	1
3756	537	3	28.150	\N	2026-09-28 08:08:11.863295	1
3757	538	1	30.850	\N	2026-09-28 08:14:34.873776	1
4650	670	3	25.750	\N	2026-10-13 05:48:48.087163	1
4651	670	4	29.800	\N	2026-10-13 05:48:48.087163	1
3761	540	1	25.450	\N	2026-09-29 05:18:02.494828	1
3762	540	2	25.400	\N	2026-09-29 05:18:02.494828	1
3763	540	3	24.900	\N	2026-09-29 05:18:02.494828	1
3764	540	4	27.150	\N	2026-09-29 05:18:02.494828	1
3765	540	5	27.850	\N	2026-09-29 05:18:02.494828	1
3766	540	6	33.850	\N	2026-09-29 05:18:02.494828	1
3767	540	7	28.150	\N	2026-09-29 05:18:02.494828	1
3768	540	8	31.050	\N	2026-09-29 05:18:02.494828	1
3769	541	1	29.400	\N	2026-09-29 05:20:03.140013	1
3770	541	2	28.000	\N	2026-09-29 05:20:03.140013	1
3771	541	3	27.250	\N	2026-09-29 05:20:03.140013	1
3772	541	4	29.200	\N	2026-09-29 05:20:03.140013	1
3773	541	5	29.450	\N	2026-09-29 05:20:03.140013	1
3774	541	6	28.150	\N	2026-09-29 05:20:03.140013	1
3775	541	7	26.900	\N	2026-09-29 05:20:03.140013	1
3776	541	8	27.200	\N	2026-09-29 05:20:03.140013	1
3777	541	9	22.950	\N	2026-09-29 05:20:03.140013	1
3778	542	1	26.200	\N	2026-09-29 05:21:09.891523	1
3779	542	2	27.350	\N	2026-09-29 05:21:09.891523	1
3780	542	3	24.200	\N	2026-09-29 05:21:09.891523	1
3781	542	4	22.950	\N	2026-09-29 05:21:09.891523	1
3782	542	5	20.200	\N	2026-09-29 05:21:09.891523	1
3783	542	6	20.350	\N	2026-09-29 05:21:09.891523	1
3784	542	7	26.250	\N	2026-09-29 05:21:09.891523	1
3785	542	8	29.650	\N	2026-09-29 05:21:09.891523	1
3786	543	1	26.350	\N	2026-09-29 05:21:54.557759	1
3787	543	2	25.450	\N	2026-09-29 05:21:54.557759	1
3788	543	3	23.750	\N	2026-09-29 05:21:54.557759	1
3789	543	4	36.000	\N	2026-09-29 05:21:54.557759	1
3790	543	5	17.550	\N	2026-09-29 05:21:54.557759	1
3791	544	1	26.050	\N	2026-09-29 05:22:42.887551	1
3792	544	2	21.900	\N	2026-09-29 05:22:42.887551	1
3793	544	3	27.000	\N	2026-09-29 05:22:42.887551	1
3794	544	4	28.600	\N	2026-09-29 05:22:42.887551	1
3795	544	5	29.650	\N	2026-09-29 05:22:42.887551	1
3796	544	6	24.050	\N	2026-09-29 05:22:42.887551	1
3797	544	7	22.750	\N	2026-09-29 05:22:42.887551	1
3798	544	8	29.200	\N	2026-09-29 05:22:42.887551	1
3799	545	1	21.850	\N	2026-09-29 05:23:25.747746	1
3800	545	2	28.800	\N	2026-09-29 05:23:25.747746	1
3801	545	3	26.450	\N	2026-09-29 05:23:25.747746	1
3802	545	4	28.100	\N	2026-09-29 05:23:25.747746	1
3803	546	1	26.650	\N	2026-09-29 05:24:31.163508	1
3804	546	2	25.200	\N	2026-09-29 05:24:31.163508	1
3805	546	3	29.400	\N	2026-09-29 05:24:31.163508	1
3806	546	4	26.700	\N	2026-09-29 05:24:31.163508	1
3807	546	5	28.950	\N	2026-09-29 05:24:31.163508	1
3808	546	6	29.700	\N	2026-09-29 05:24:31.163508	1
3809	546	7	30.200	\N	2026-09-29 05:24:31.163508	1
3810	546	8	26.300	\N	2026-09-29 05:24:31.163508	1
3811	547	1	24.500	\N	2026-09-29 05:25:50.119306	1
3812	547	2	23.400	\N	2026-09-29 05:25:50.119306	1
3813	547	3	24.650	\N	2026-09-29 05:25:50.119306	1
3814	547	4	19.800	\N	2026-09-29 05:25:50.119306	1
3815	547	5	21.250	\N	2026-09-29 05:25:50.119306	1
3816	547	6	28.150	\N	2026-09-29 05:25:50.119306	1
3817	548	1	22.650	\N	2026-09-29 05:26:36.661539	1
3818	548	2	32.100	\N	2026-09-29 05:26:36.661539	1
3819	548	3	22.350	\N	2026-09-29 05:26:36.661539	1
3820	548	4	25.700	\N	2026-09-29 05:26:36.661539	1
3821	548	5	21.350	\N	2026-09-29 05:26:36.661539	1
3822	548	6	25.350	\N	2026-09-29 05:26:36.661539	1
3823	548	7	22.500	\N	2026-09-29 05:26:36.661539	1
3824	548	8	20.600	\N	2026-09-29 05:26:36.661539	1
3825	549	1	28.100	\N	2026-09-30 05:30:01.986237	1
3826	549	2	19.050	\N	2026-09-30 05:30:01.986237	1
3827	549	3	29.700	\N	2026-09-30 05:30:01.986237	1
3828	549	4	26.300	\N	2026-09-30 05:30:01.986237	1
3829	549	5	27.700	\N	2026-09-30 05:30:01.986237	1
3830	549	6	24.600	\N	2026-09-30 05:30:01.986237	1
3831	549	7	22.700	\N	2026-09-30 05:30:01.986237	1
3832	550	1	28.950	\N	2026-09-30 05:30:48.181348	1
3833	550	2	28.800	\N	2026-09-30 05:30:48.181348	1
3834	550	3	28.000	\N	2026-09-30 05:30:48.181348	1
3835	550	4	25.350	\N	2026-09-30 05:30:48.181348	1
3836	550	5	31.150	\N	2026-09-30 05:30:48.181348	1
3837	550	6	33.350	\N	2026-09-30 05:30:48.181348	1
3838	550	7	30.350	\N	2026-09-30 05:30:48.181348	1
3839	550	8	31.150	\N	2026-09-30 05:30:48.181348	1
3840	551	1	27.900	\N	2026-09-30 05:31:29.462812	1
3841	551	2	22.600	\N	2026-09-30 05:31:29.462812	1
3842	551	3	25.350	\N	2026-09-30 05:31:29.462812	1
3843	551	4	25.500	\N	2026-09-30 05:31:29.462812	1
3844	551	5	28.150	\N	2026-09-30 05:31:29.462812	1
3845	551	6	23.350	\N	2026-09-30 05:31:29.462812	1
3846	551	7	28.100	\N	2026-09-30 05:31:29.462812	1
3847	551	8	24.400	\N	2026-09-30 05:31:29.462812	1
3848	552	1	29.750	\N	2026-09-30 05:32:38.17242	1
3849	552	2	28.050	\N	2026-09-30 05:32:38.17242	1
3850	552	3	29.150	\N	2026-09-30 05:32:38.17242	1
3851	552	4	29.850	\N	2026-09-30 05:32:38.17242	1
3852	552	5	26.100	\N	2026-09-30 05:32:38.17242	1
3853	552	6	25.500	\N	2026-09-30 05:32:38.17242	1
3854	552	7	21.450	\N	2026-09-30 05:32:38.17242	1
3855	552	8	28.200	\N	2026-09-30 05:32:38.17242	1
3856	553	1	29.600	\N	2026-09-30 05:33:22.943902	1
3857	553	2	21.800	\N	2026-09-30 05:33:22.943902	1
3858	553	3	27.300	\N	2026-09-30 05:33:22.943902	1
3859	553	4	29.350	\N	2026-09-30 05:33:22.943902	1
3860	553	5	29.450	\N	2026-09-30 05:33:22.943902	1
3861	553	6	29.250	\N	2026-09-30 05:33:22.943902	1
3862	553	7	24.600	\N	2026-09-30 05:33:22.943902	1
3863	553	8	29.350	\N	2026-09-30 05:33:22.943902	1
3864	554	1	22.500	\N	2026-09-30 05:34:09.582362	1
3865	554	2	23.600	\N	2026-09-30 05:34:09.582362	1
3866	554	3	20.100	\N	2026-09-30 05:34:09.582362	1
3867	554	4	28.850	\N	2026-09-30 05:34:09.582362	1
3868	554	5	24.400	\N	2026-09-30 05:34:09.582362	1
3869	554	6	21.450	\N	2026-09-30 05:34:09.582362	1
3870	554	7	25.900	\N	2026-09-30 05:34:09.582362	1
3871	554	8	24.400	\N	2026-09-30 05:34:09.582362	1
3872	555	1	29.800	\N	2026-10-01 05:26:16.399653	1
3873	555	2	28.050	\N	2026-10-01 05:26:16.399653	1
3874	555	3	30.250	\N	2026-10-01 05:26:16.399653	1
3875	555	4	28.800	\N	2026-10-01 05:26:16.399653	1
3876	555	5	30.800	\N	2026-10-01 05:26:16.399653	1
3877	555	6	30.750	\N	2026-10-01 05:26:16.399653	1
3878	555	7	24.900	\N	2026-10-01 05:26:16.399653	1
3879	556	1	27.800	\N	2026-10-01 05:29:46.946326	1
3880	556	2	30.850	\N	2026-10-01 05:29:46.946326	1
3881	556	3	26.500	\N	2026-10-01 05:29:46.946326	1
3882	556	4	28.750	\N	2026-10-01 05:29:46.946326	1
3883	556	5	24.350	\N	2026-10-01 05:29:46.946326	1
3884	556	6	30.200	\N	2026-10-01 05:29:46.946326	1
3885	556	7	33.150	\N	2026-10-01 05:29:46.946326	1
3886	556	8	22.950	\N	2026-10-01 05:29:46.946326	1
3887	556	9	26.950	\N	2026-10-01 05:29:46.946326	1
4652	670	5	30.300	\N	2026-10-13 05:48:48.087163	1
4653	670	6	23.250	\N	2026-10-13 05:48:48.087163	1
4654	670	7	30.500	\N	2026-10-13 05:48:48.087163	1
4655	671	1	22.000	\N	2026-10-13 05:49:39.081719	1
4656	671	2	29.100	\N	2026-10-13 05:49:39.081719	1
4657	671	3	29.400	\N	2026-10-13 05:49:39.081719	1
4658	671	4	29.950	\N	2026-10-13 05:49:39.081719	1
4659	671	5	26.000	\N	2026-10-13 05:49:39.081719	1
4660	671	6	30.750	\N	2026-10-13 05:49:39.081719	1
3897	558	1	29.500	\N	2026-10-01 05:31:36.643954	1
3898	558	2	27.400	\N	2026-10-01 05:31:36.643954	1
3899	558	3	26.250	\N	2026-10-01 05:31:36.643954	1
3900	558	4	28.750	\N	2026-10-01 05:31:36.643954	1
3901	558	5	23.150	\N	2026-10-01 05:31:36.643954	1
3902	559	1	26.450	\N	2026-10-01 05:32:51.571835	1
3903	559	2	32.450	\N	2026-10-01 05:32:51.571835	1
3904	559	3	26.500	\N	2026-10-01 05:32:51.571835	1
3905	559	4	31.400	\N	2026-10-01 05:32:51.571835	1
3906	559	5	32.350	\N	2026-10-01 05:32:51.571835	1
3907	559	6	30.600	\N	2026-10-01 05:32:51.571835	1
3908	559	7	29.000	\N	2026-10-01 05:32:51.571835	1
3909	559	8	29.400	\N	2026-10-01 05:32:51.571835	1
3910	559	9	28.050	\N	2026-10-01 05:32:51.571835	1
3911	560	1	32.750	\N	2026-10-01 05:34:08.007716	1
3912	560	2	29.250	\N	2026-10-01 05:34:08.007716	1
3913	560	3	24.200	\N	2026-10-01 05:34:08.007716	1
3914	560	4	25.600	\N	2026-10-01 05:34:08.007716	1
3915	560	5	29.300	\N	2026-10-01 05:34:08.007716	1
3916	560	6	30.000	\N	2026-10-01 05:34:08.007716	1
3917	560	7	22.900	\N	2026-10-01 05:34:08.007716	1
3918	560	8	29.250	\N	2026-10-01 05:34:08.007716	1
3919	560	9	26.050	\N	2026-10-01 05:34:08.007716	1
3920	561	1	27.650	\N	2026-10-01 05:34:56.527885	1
3921	561	2	25.500	\N	2026-10-01 05:34:56.527885	1
3922	561	3	26.250	\N	2026-10-01 05:34:56.527885	1
3923	561	4	25.300	\N	2026-10-01 05:34:56.527885	1
3924	561	5	29.250	\N	2026-10-01 05:34:56.527885	1
3925	561	6	25.500	\N	2026-10-01 05:34:56.527885	1
3926	561	7	30.200	\N	2026-10-01 05:34:56.527885	1
3927	561	8	29.350	\N	2026-10-01 05:34:56.527885	1
3928	561	9	32.150	\N	2026-10-01 05:34:56.527885	1
3929	562	1	25.950	\N	2026-10-01 05:35:59.118356	1
3930	562	2	19.250	\N	2026-10-01 05:35:59.118356	1
3931	562	3	24.350	\N	2026-10-01 05:35:59.118356	1
3932	562	4	24.350	\N	2026-10-01 05:35:59.118356	1
3933	562	5	25.500	\N	2026-10-01 05:35:59.118356	1
3934	562	6	23.750	\N	2026-10-01 05:35:59.118356	1
3935	562	7	22.800	\N	2026-10-01 05:35:59.118356	1
3936	562	8	21.200	\N	2026-10-01 05:35:59.118356	1
3937	562	9	26.050	\N	2026-10-01 05:35:59.118356	1
3938	557	1	28.700	\N	2026-10-01 05:39:10.275171	1
3939	557	2	28.700	\N	2026-10-01 05:39:10.275171	1
3940	557	3	31.050	\N	2026-10-01 05:39:10.275171	1
3941	557	4	27.750	\N	2026-10-01 05:39:10.275171	1
3942	557	5	27.450	\N	2026-10-01 05:39:10.275171	1
3943	557	6	29.650	\N	2026-10-01 05:39:10.275171	1
3944	557	7	27.250	\N	2026-10-01 05:39:10.275171	1
3945	557	8	27.200	\N	2026-10-01 05:39:10.275171	1
3946	557	9	29.100	\N	2026-10-01 05:39:10.275171	1
3947	563	1	27.750	\N	2026-10-02 05:34:39.633814	1
3948	563	2	30.900	\N	2026-10-02 05:34:39.633814	1
3949	563	3	29.900	\N	2026-10-02 05:34:39.633814	1
3950	563	4	30.050	\N	2026-10-02 05:34:39.633814	1
3951	563	5	28.450	\N	2026-10-02 05:34:39.633814	1
3952	563	6	22.000	\N	2026-10-02 05:34:39.633814	1
3953	563	7	27.300	\N	2026-10-02 05:34:39.633814	1
3954	563	8	22.050	\N	2026-10-02 05:34:39.633814	1
3955	564	1	29.900	\N	2026-10-02 05:35:37.890683	1
3956	564	2	26.700	\N	2026-10-02 05:35:37.890683	1
3957	564	3	27.850	\N	2026-10-02 05:35:37.890683	1
3958	564	4	29.950	\N	2026-10-02 05:35:37.890683	1
3959	564	5	29.300	\N	2026-10-02 05:35:37.890683	1
3960	564	6	27.050	\N	2026-10-02 05:35:37.890683	1
3961	564	7	21.550	\N	2026-10-02 05:35:37.890683	1
3962	564	8	29.300	\N	2026-10-02 05:35:37.890683	1
3963	564	9	24.750	\N	2026-10-02 05:35:37.890683	1
3964	565	1	25.800	\N	2026-10-02 05:36:22.384184	1
3965	565	2	31.300	\N	2026-10-02 05:36:22.384184	1
3966	565	3	30.100	\N	2026-10-02 05:36:22.384184	1
3967	565	4	30.550	\N	2026-10-02 05:36:22.384184	1
3968	565	5	27.850	\N	2026-10-02 05:36:22.384184	1
3969	565	6	29.800	\N	2026-10-02 05:36:22.384184	1
3970	565	7	34.800	\N	2026-10-02 05:36:22.384184	1
3971	566	1	29.500	\N	2026-10-02 05:37:09.783354	1
3972	566	2	33.050	\N	2026-10-02 05:37:09.783354	1
3973	566	3	28.200	\N	2026-10-02 05:37:09.783354	1
3974	566	4	28.250	\N	2026-10-02 05:37:09.783354	1
3975	566	5	24.800	\N	2026-10-02 05:37:09.783354	1
3976	566	6	32.250	\N	2026-10-02 05:37:09.783354	1
3977	567	1	29.700	\N	2026-10-02 05:38:15.971208	1
3978	567	2	24.100	\N	2026-10-02 05:38:15.971208	1
3979	567	3	29.650	\N	2026-10-02 05:38:15.971208	1
3980	567	4	29.150	\N	2026-10-02 05:38:15.971208	1
3981	567	5	27.600	\N	2026-10-02 05:38:15.971208	1
3982	567	6	29.550	\N	2026-10-02 05:38:15.971208	1
3983	567	7	29.650	\N	2026-10-02 05:38:15.971208	1
3984	567	8	29.350	\N	2026-10-02 05:38:15.971208	1
3985	567	9	27.450	\N	2026-10-02 05:38:15.971208	1
3986	568	1	29.100	\N	2026-10-02 05:39:10.804242	1
3987	568	2	24.600	\N	2026-10-02 05:39:10.804242	1
3988	568	3	27.100	\N	2026-10-02 05:39:10.804242	1
3989	568	4	28.900	\N	2026-10-02 05:39:10.804242	1
3990	568	5	25.350	\N	2026-10-02 05:39:10.804242	1
3991	568	6	29.050	\N	2026-10-02 05:39:10.804242	1
3992	568	7	30.100	\N	2026-10-02 05:39:10.804242	1
3993	568	8	25.150	\N	2026-10-02 05:39:10.804242	1
3994	568	9	28.150	\N	2026-10-02 05:39:10.804242	1
3995	569	1	29.350	\N	2026-10-02 05:40:04.629888	1
3996	569	2	28.800	\N	2026-10-02 05:40:04.629888	1
3997	569	3	29.800	\N	2026-10-02 05:40:04.629888	1
3998	569	4	28.900	\N	2026-10-02 05:40:04.629888	1
3999	569	5	25.900	\N	2026-10-02 05:40:04.629888	1
4000	569	6	28.350	\N	2026-10-02 05:40:04.629888	1
4001	569	7	30.650	\N	2026-10-02 05:40:04.629888	1
4002	569	8	28.550	\N	2026-10-02 05:40:04.629888	1
4003	569	9	25.200	\N	2026-10-02 05:40:04.629888	1
4004	570	1	26.550	\N	2026-10-02 05:41:07.345269	1
4005	570	2	20.450	\N	2026-10-02 05:41:07.345269	1
4006	570	3	28.900	\N	2026-10-02 05:41:07.345269	1
4007	570	4	22.600	\N	2026-10-02 05:41:07.345269	1
4008	570	5	19.450	\N	2026-10-02 05:41:07.345269	1
4009	570	6	21.900	\N	2026-10-02 05:41:07.345269	1
4010	570	7	26.100	\N	2026-10-02 05:41:07.345269	1
4011	570	8	25.050	\N	2026-10-02 05:41:07.345269	1
4012	570	9	22.350	\N	2026-10-02 05:41:07.345269	1
4013	571	1	30.400	\N	2026-10-03 06:10:33.999335	1
4014	571	2	29.650	\N	2026-10-03 06:10:33.999335	1
4015	571	3	28.950	\N	2026-10-03 06:10:33.999335	1
4016	571	4	29.550	\N	2026-10-03 06:10:33.999335	1
4017	571	5	29.750	\N	2026-10-03 06:10:33.999335	1
4018	571	6	28.950	\N	2026-10-03 06:10:33.999335	1
4019	571	7	27.700	\N	2026-10-03 06:10:33.999335	1
4020	571	8	24.700	\N	2026-10-03 06:10:33.999335	1
4021	572	1	27.850	\N	2026-10-03 06:12:01.409152	1
4022	572	2	30.400	\N	2026-10-03 06:12:01.409152	1
4023	572	3	32.100	\N	2026-10-03 06:12:01.409152	1
4024	572	4	26.750	\N	2026-10-03 06:12:01.409152	1
4025	572	5	29.800	\N	2026-10-03 06:12:01.409152	1
4026	572	6	27.450	\N	2026-10-03 06:12:01.409152	1
4027	572	7	21.350	\N	2026-10-03 06:12:01.409152	1
4028	572	8	24.950	\N	2026-10-03 06:12:01.409152	1
4029	573	1	29.500	\N	2026-10-03 06:12:50.027279	1
4030	573	2	29.400	\N	2026-10-03 06:12:50.027279	1
4031	573	3	26.900	\N	2026-10-03 06:12:50.027279	1
4032	573	4	32.050	\N	2026-10-03 06:12:50.027279	1
4033	573	5	27.650	\N	2026-10-03 06:12:50.027279	1
4034	573	6	27.600	\N	2026-10-03 06:12:50.027279	1
4035	573	7	26.000	\N	2026-10-03 06:12:50.027279	1
4036	573	8	26.950	\N	2026-10-03 06:12:50.027279	1
4037	574	1	21.600	\N	2026-10-03 06:13:31.903203	1
4038	574	2	29.500	\N	2026-10-03 06:13:31.903203	1
4039	574	3	27.650	\N	2026-10-03 06:13:31.903203	1
4040	574	4	23.100	\N	2026-10-03 06:13:31.903203	1
4041	575	1	28.550	\N	2026-10-03 06:14:20.181537	1
4042	575	2	25.950	\N	2026-10-03 06:14:20.181537	1
4043	575	3	31.050	\N	2026-10-03 06:14:20.181537	1
4044	575	4	25.400	\N	2026-10-03 06:14:20.181537	1
4045	575	5	27.650	\N	2026-10-03 06:14:20.181537	1
4046	575	6	26.150	\N	2026-10-03 06:14:20.181537	1
4047	575	7	26.750	\N	2026-10-03 06:14:20.181537	1
4048	576	1	28.400	\N	2026-10-03 06:15:59.420095	1
4049	576	2	27.350	\N	2026-10-03 06:15:59.420095	1
4050	576	3	28.350	\N	2026-10-03 06:15:59.420095	1
4051	576	4	28.100	\N	2026-10-03 06:15:59.420095	1
4052	576	5	29.250	\N	2026-10-03 06:15:59.420095	1
4053	576	6	29.250	\N	2026-10-03 06:15:59.420095	1
4054	576	7	28.050	\N	2026-10-03 06:15:59.420095	1
4055	576	8	28.650	\N	2026-10-03 06:15:59.420095	1
4056	576	9	30.700	\N	2026-10-03 06:15:59.420095	1
4057	577	1	28.850	\N	2026-10-03 06:16:52.186835	1
4058	577	2	22.750	\N	2026-10-03 06:16:52.186835	1
4059	577	3	27.850	\N	2026-10-03 06:16:52.186835	1
4060	577	4	29.300	\N	2026-10-03 06:16:52.186835	1
4061	577	5	21.800	\N	2026-10-03 06:16:52.186835	1
4062	577	6	24.750	\N	2026-10-03 06:16:52.186835	1
4063	577	7	30.750	\N	2026-10-03 06:16:52.186835	1
4064	577	8	31.350	\N	2026-10-03 06:16:52.186835	1
4065	577	9	27.650	\N	2026-10-03 06:16:52.186835	1
4066	578	1	30.950	\N	2026-10-03 06:17:39.976253	1
4067	578	2	28.200	\N	2026-10-03 06:17:39.976253	1
4068	578	3	27.250	\N	2026-10-03 06:17:39.976253	1
4069	578	4	26.300	\N	2026-10-03 06:17:39.976253	1
4070	578	5	30.400	\N	2026-10-03 06:17:39.976253	1
4071	578	6	30.200	\N	2026-10-03 06:17:39.976253	1
4072	578	7	26.100	\N	2026-10-03 06:17:39.976253	1
4073	578	8	23.850	\N	2026-10-03 06:17:39.976253	1
4074	578	9	26.800	\N	2026-10-03 06:17:39.976253	1
4075	579	1	28.300	\N	2026-10-03 06:18:12.318667	1
4076	579	2	25.350	\N	2026-10-03 06:18:12.318667	1
4077	579	3	24.350	\N	2026-10-03 06:18:12.318667	1
4078	579	4	28.250	\N	2026-10-03 06:18:12.318667	1
4079	580	1	21.850	\N	2026-10-03 06:18:58.489635	1
4080	580	2	21.500	\N	2026-10-03 06:18:58.489635	1
4081	580	3	24.800	\N	2026-10-03 06:18:58.489635	1
4082	580	4	26.600	\N	2026-10-03 06:18:58.489635	1
4083	580	5	24.150	\N	2026-10-03 06:18:58.489635	1
4084	580	6	25.200	\N	2026-10-03 06:18:58.489635	1
4085	580	7	25.350	\N	2026-10-03 06:18:58.489635	1
4086	580	8	20.600	\N	2026-10-03 06:18:58.489635	1
4087	580	9	29.000	\N	2026-10-03 06:18:58.489635	1
4088	581	1	31.250	\N	2026-10-04 05:17:17.223417	1
4089	581	2	30.650	\N	2026-10-04 05:17:17.223417	1
4090	581	3	30.200	\N	2026-10-04 05:17:17.223417	1
4091	581	4	30.600	\N	2026-10-04 05:17:17.223417	1
4092	581	5	30.350	\N	2026-10-04 05:17:17.223417	1
4093	581	6	27.800	\N	2026-10-04 05:17:17.223417	1
4094	581	7	24.600	\N	2026-10-04 05:17:17.223417	1
4095	581	8	25.550	\N	2026-10-04 05:17:17.223417	1
4096	581	9	21.850	\N	2026-10-04 05:17:17.223417	1
4097	582	1	29.400	\N	2026-10-04 05:18:16.929101	1
4098	582	2	29.250	\N	2026-10-04 05:18:16.929101	1
4099	582	3	28.350	\N	2026-10-04 05:18:16.929101	1
4100	582	4	29.850	\N	2026-10-04 05:18:16.929101	1
4101	582	5	30.300	\N	2026-10-04 05:18:16.929101	1
4102	582	6	29.000	\N	2026-10-04 05:18:16.929101	1
4103	582	7	24.400	\N	2026-10-04 05:18:16.929101	1
4104	582	8	23.550	\N	2026-10-04 05:18:16.929101	1
4105	582	9	22.400	\N	2026-10-04 05:18:16.929101	1
4106	583	1	27.550	\N	2026-10-04 05:20:43.80722	1
4107	583	2	29.750	\N	2026-10-04 05:20:43.80722	1
4108	583	3	28.500	\N	2026-10-04 05:20:43.80722	1
4109	583	4	28.300	\N	2026-10-04 05:20:43.80722	1
4110	583	5	27.450	\N	2026-10-04 05:20:43.80722	1
4111	583	6	30.450	\N	2026-10-04 05:20:43.80722	1
4112	583	7	25.950	\N	2026-10-04 05:20:43.80722	1
4113	583	8	26.100	\N	2026-10-04 05:20:43.80722	1
4114	583	9	29.000	\N	2026-10-04 05:20:43.80722	1
4115	584	1	26.000	\N	2026-10-04 05:21:23.16264	1
4116	584	2	22.200	\N	2026-10-04 05:21:23.16264	1
4117	584	3	27.150	\N	2026-10-04 05:21:23.16264	1
4118	584	4	24.200	\N	2026-10-04 05:21:23.16264	1
4119	584	5	20.600	\N	2026-10-04 05:21:23.16264	1
4120	584	6	23.750	\N	2026-10-04 05:21:23.16264	1
4121	585	1	31.300	\N	2026-10-04 05:22:09.578522	1
4122	585	2	28.350	\N	2026-10-04 05:22:09.578522	1
4123	585	3	26.750	\N	2026-10-04 05:22:09.578522	1
4124	585	4	28.950	\N	2026-10-04 05:22:09.578522	1
4125	585	5	32.450	\N	2026-10-04 05:22:09.578522	1
4126	585	6	31.100	\N	2026-10-04 05:22:09.578522	1
4127	585	7	32.100	\N	2026-10-04 05:22:09.578522	1
4128	586	1	29.100	\N	2026-10-04 06:28:30.706465	1
4129	586	2	29.150	\N	2026-10-04 06:28:30.706465	1
4130	586	3	28.700	\N	2026-10-04 06:28:30.706465	1
4131	586	4	28.900	\N	2026-10-04 06:28:30.706465	1
4132	586	5	22.600	\N	2026-10-04 06:28:30.706465	1
4133	586	6	24.550	\N	2026-10-04 06:28:30.706465	1
4134	586	7	29.000	\N	2026-10-04 06:28:30.706465	1
4135	586	8	28.750	\N	2026-10-04 06:28:30.706465	1
4136	586	9	27.000	\N	2026-10-04 06:28:30.706465	1
4137	587	1	27.250	\N	2026-10-04 06:30:03.39998	1
4138	587	2	15.550	\N	2026-10-04 06:30:03.39998	1
4139	587	3	27.700	\N	2026-10-04 06:30:03.39998	1
4140	587	4	29.200	\N	2026-10-04 06:30:03.39998	1
4141	587	5	28.750	\N	2026-10-04 06:30:03.39998	1
4142	587	6	27.400	\N	2026-10-04 06:30:03.39998	1
4143	587	7	19.950	\N	2026-10-04 06:30:03.39998	1
4144	587	8	30.750	\N	2026-10-04 06:30:03.39998	1
4145	587	9	28.450	\N	2026-10-04 06:30:03.39998	1
4146	588	1	31.500	\N	2026-10-04 06:31:04.724932	1
4147	588	2	25.850	\N	2026-10-04 06:31:04.724932	1
4148	588	3	22.900	\N	2026-10-04 06:31:04.724932	1
4149	588	4	22.850	\N	2026-10-04 06:31:04.724932	1
4150	588	5	26.850	\N	2026-10-04 06:31:04.724932	1
4151	588	6	30.850	\N	2026-10-04 06:31:04.724932	1
4152	588	7	28.600	\N	2026-10-04 06:31:04.724932	1
4153	588	8	30.550	\N	2026-10-04 06:31:04.724932	1
4154	588	9	30.350	\N	2026-10-04 06:31:04.724932	1
4155	589	1	24.500	\N	2026-10-04 06:31:47.662378	1
4156	589	2	23.550	\N	2026-10-04 06:31:47.662378	1
4157	589	3	28.700	\N	2026-10-04 06:31:47.662378	1
4158	589	4	32.700	\N	2026-10-04 06:31:47.662378	1
4159	589	5	15.200	\N	2026-10-04 06:31:47.662378	1
4160	589	6	21.050	\N	2026-10-04 06:31:47.662378	1
4161	590	1	23.900	\N	2026-10-04 06:32:48.028686	1
4162	590	2	18.650	\N	2026-10-04 06:32:48.028686	1
4163	590	3	24.900	\N	2026-10-04 06:32:48.028686	1
4164	590	4	26.800	\N	2026-10-04 06:32:48.028686	1
4165	590	5	26.100	\N	2026-10-04 06:32:48.028686	1
4166	590	6	25.950	\N	2026-10-04 06:32:48.028686	1
4167	590	7	25.300	\N	2026-10-04 06:32:48.028686	1
4168	590	8	23.550	\N	2026-10-04 06:32:48.028686	1
4169	590	9	29.050	\N	2026-10-04 06:32:48.028686	1
4170	591	1	27.500	\N	2026-10-05 05:51:43.797266	1
4171	591	2	15.800	\N	2026-10-05 05:51:43.797266	1
4172	592	1	19.600	\N	2026-10-05 05:52:00.816441	1
4173	592	2	24.300	\N	2026-10-05 05:52:00.816441	1
4174	593	1	15.650	\N	2026-10-05 05:52:41.276718	1
4175	593	2	22.150	\N	2026-10-05 05:52:41.276718	1
4176	593	3	26.400	\N	2026-10-05 05:52:41.276718	1
4177	593	4	22.150	\N	2026-10-05 05:52:41.276718	1
4178	594	1	17.650	\N	2026-10-05 05:53:29.162787	1
4179	594	2	32.950	\N	2026-10-05 05:53:29.162787	1
4180	594	3	12.800	\N	2026-10-05 05:53:29.162787	1
4181	594	4	22.600	\N	2026-10-05 05:53:29.162787	1
4182	595	1	28.600	\N	2026-10-05 05:53:58.002823	1
4183	595	2	26.300	\N	2026-10-05 05:53:58.002823	1
4184	596	1	23.000	\N	2026-10-05 05:54:26.223315	1
4185	596	2	23.450	\N	2026-10-05 05:54:26.223315	1
4186	596	3	28.500	\N	2026-10-05 05:54:26.223315	1
4187	597	1	29.500	\N	2026-10-05 05:55:43.283734	1
4188	597	2	29.550	\N	2026-10-05 05:55:43.283734	1
4189	597	3	28.250	\N	2026-10-05 05:55:43.283734	1
4190	597	4	30.300	\N	2026-10-05 05:55:43.283734	1
4191	597	5	28.000	\N	2026-10-05 05:55:43.283734	1
4192	597	6	29.750	\N	2026-10-05 05:55:43.283734	1
4193	597	7	31.500	\N	2026-10-05 05:55:43.283734	1
4194	597	8	30.100	\N	2026-10-05 05:55:43.283734	1
4195	597	9	30.400	\N	2026-10-05 05:55:43.283734	1
4196	597	10	28.700	\N	2026-10-05 05:55:43.283734	1
4197	598	1	27.900	\N	2026-10-05 05:56:48.577325	1
4198	598	2	20.950	\N	2026-10-05 05:56:48.577325	1
4199	598	3	29.450	\N	2026-10-05 05:56:48.577325	1
4200	598	4	32.900	\N	2026-10-05 05:56:48.577325	1
4201	598	5	30.750	\N	2026-10-05 05:56:48.577325	1
4202	598	6	28.450	\N	2026-10-05 05:56:48.577325	1
4203	598	7	30.600	\N	2026-10-05 05:56:48.577325	1
4204	598	8	28.650	\N	2026-10-05 05:56:48.577325	1
4205	598	9	29.200	\N	2026-10-05 05:56:48.577325	1
4206	598	10	27.150	\N	2026-10-05 05:56:48.577325	1
4207	598	11	31.400	\N	2026-10-05 05:56:48.577325	1
4208	598	12	27.050	\N	2026-10-05 05:56:48.577325	1
4209	599	1	27.400	\N	2026-10-05 05:57:47.127555	1
4210	599	2	27.600	\N	2026-10-05 05:57:47.127555	1
4211	599	3	27.900	\N	2026-10-05 05:57:47.127555	1
4212	599	4	26.700	\N	2026-10-05 05:57:47.127555	1
4213	599	5	30.500	\N	2026-10-05 05:57:47.127555	1
4214	599	6	28.850	\N	2026-10-05 05:57:47.127555	1
4215	599	7	28.800	\N	2026-10-05 05:57:47.127555	1
4216	599	8	29.100	\N	2026-10-05 05:57:47.127555	1
4217	599	9	29.100	\N	2026-10-05 05:57:47.127555	1
4218	599	10	27.050	\N	2026-10-05 05:57:47.127555	1
4219	599	11	29.700	\N	2026-10-05 05:57:47.127555	1
4220	599	12	29.100	\N	2026-10-05 05:57:47.127555	1
4221	600	1	25.350	\N	2026-10-05 05:58:32.200984	1
4222	600	2	23.600	\N	2026-10-05 05:58:32.200984	1
4223	600	3	30.400	\N	2026-10-05 05:58:32.200984	1
4224	600	4	32.950	\N	2026-10-05 05:58:32.200984	1
4225	600	5	28.900	\N	2026-10-05 05:58:32.200984	1
4226	600	6	18.850	\N	2026-10-05 05:58:32.200984	1
4227	600	7	21.050	\N	2026-10-05 05:58:32.200984	1
4228	601	1	31.950	\N	2026-10-05 05:59:23.910409	1
4229	601	2	30.800	\N	2026-10-05 05:59:23.910409	1
4230	601	3	30.950	\N	2026-10-05 05:59:23.910409	1
4231	601	4	27.100	\N	2026-10-05 05:59:23.910409	1
4232	601	5	31.550	\N	2026-10-05 05:59:23.910409	1
4233	601	6	31.450	\N	2026-10-05 05:59:23.910409	1
4234	601	7	29.550	\N	2026-10-05 05:59:23.910409	1
4235	601	8	33.050	\N	2026-10-05 05:59:23.910409	1
4236	601	9	32.850	\N	2026-10-05 05:59:23.910409	1
4237	601	10	26.750	\N	2026-10-05 05:59:23.910409	1
4238	602	1	30.250	\N	2026-10-06 05:13:03.115378	1
4239	602	2	26.450	\N	2026-10-06 05:13:03.115378	1
4240	602	3	23.550	\N	2026-10-06 05:13:03.115378	1
4241	602	4	30.800	\N	2026-10-06 05:13:03.115378	1
4242	602	5	28.650	\N	2026-10-06 05:13:03.115378	1
4243	602	6	25.950	\N	2026-10-06 05:13:03.115378	1
4244	602	7	29.250	\N	2026-10-06 05:13:03.115378	1
4245	603	1	27.300	\N	2026-10-06 05:13:58.306602	1
4246	603	2	21.550	\N	2026-10-06 05:13:58.306602	1
4247	603	3	26.700	\N	2026-10-06 05:13:58.306602	1
4248	603	4	27.300	\N	2026-10-06 05:13:58.306602	1
4249	603	5	19.800	\N	2026-10-06 05:13:58.306602	1
4250	603	6	21.450	\N	2026-10-06 05:13:58.306602	1
4251	603	7	29.400	\N	2026-10-06 05:13:58.306602	1
4252	603	8	29.350	\N	2026-10-06 05:13:58.306602	1
4253	603	9	29.500	\N	2026-10-06 05:13:58.306602	1
4254	604	1	28.650	\N	2026-10-06 05:14:47.270911	1
4255	604	2	22.800	\N	2026-10-06 05:14:47.270911	1
4256	604	3	25.900	\N	2026-10-06 05:14:47.270911	1
4257	604	4	16.800	\N	2026-10-06 05:14:47.270911	1
4258	604	5	23.950	\N	2026-10-06 05:14:47.270911	1
4259	604	6	32.200	\N	2026-10-06 05:14:47.270911	1
4260	604	7	21.550	\N	2026-10-06 05:14:47.270911	1
4261	604	8	29.350	\N	2026-10-06 05:14:47.270911	1
4262	605	1	20.250	\N	2026-10-06 05:15:27.881095	1
4263	605	2	17.350	\N	2026-10-06 05:15:27.881095	1
4264	605	3	27.450	\N	2026-10-06 05:15:27.881095	1
4265	605	4	17.100	\N	2026-10-06 05:15:27.881095	1
4266	606	1	25.250	\N	2026-10-06 05:16:16.184007	1
4267	606	2	22.750	\N	2026-10-06 05:16:16.184007	1
4268	606	3	23.150	\N	2026-10-06 05:16:16.184007	1
4269	606	4	25.400	\N	2026-10-06 05:16:16.184007	1
4270	606	5	27.100	\N	2026-10-06 05:16:16.184007	1
4271	606	6	20.650	\N	2026-10-06 05:16:16.184007	1
4272	606	7	23.950	\N	2026-10-06 05:16:16.184007	1
4273	606	8	25.800	\N	2026-10-06 05:16:16.184007	1
4274	606	9	26.650	\N	2026-10-06 05:16:16.184007	1
4275	607	1	33.300	\N	2026-10-06 05:17:45.277627	1
4276	607	2	31.800	\N	2026-10-06 05:17:45.277627	1
4277	607	3	31.450	\N	2026-10-06 05:17:45.277627	1
4278	607	4	30.650	\N	2026-10-06 05:17:45.277627	1
4279	607	5	29.150	\N	2026-10-06 05:17:45.277627	1
4280	607	6	27.300	\N	2026-10-06 05:17:45.277627	1
4281	607	7	30.700	\N	2026-10-06 05:17:45.277627	1
4282	607	8	29.800	\N	2026-10-06 05:17:45.277627	1
4283	608	1	22.000	\N	2026-10-06 05:18:35.701439	1
4284	608	2	30.700	\N	2026-10-06 05:18:35.701439	1
4285	608	3	29.050	\N	2026-10-06 05:18:35.701439	1
4286	608	4	22.950	\N	2026-10-06 05:18:35.701439	1
4287	608	5	28.650	\N	2026-10-06 05:18:35.701439	1
4288	608	6	28.250	\N	2026-10-06 05:18:35.701439	1
4289	608	7	29.900	\N	2026-10-06 05:18:35.701439	1
4290	608	8	27.000	\N	2026-10-06 05:18:35.701439	1
4291	608	9	29.400	\N	2026-10-06 05:18:35.701439	1
4292	609	1	29.750	\N	2026-10-06 05:19:15.303879	1
4293	609	2	29.600	\N	2026-10-06 05:19:15.303879	1
4294	609	3	28.000	\N	2026-10-06 05:19:15.303879	1
4295	609	4	27.000	\N	2026-10-06 05:19:15.303879	1
4296	609	5	29.100	\N	2026-10-06 05:19:15.303879	1
4297	609	6	28.450	\N	2026-10-06 05:19:15.303879	1
4298	610	1	28.650	\N	2026-10-06 05:20:03.948708	1
4299	610	2	29.000	\N	2026-10-06 05:20:03.948708	1
4300	610	3	27.750	\N	2026-10-06 05:20:03.948708	1
4301	610	4	29.650	\N	2026-10-06 05:20:03.948708	1
4302	610	5	25.150	\N	2026-10-06 05:20:03.948708	1
4303	610	6	26.850	\N	2026-10-06 05:20:03.948708	1
4304	610	7	26.650	\N	2026-10-06 05:20:03.948708	1
4305	610	8	28.050	\N	2026-10-06 05:20:03.948708	1
4306	611	1	24.250	\N	2026-10-07 05:23:33.898802	1
4307	611	2	29.300	\N	2026-10-07 05:23:33.898802	1
4308	611	3	24.750	\N	2026-10-07 05:23:33.898802	1
4309	611	4	27.250	\N	2026-10-07 05:23:33.898802	1
4310	611	5	27.350	\N	2026-10-07 05:23:33.898802	1
4311	611	6	28.350	\N	2026-10-07 05:23:33.898802	1
4312	611	7	30.500	\N	2026-10-07 05:23:33.898802	1
4313	611	8	16.050	\N	2026-10-07 05:23:33.898802	1
4314	612	1	24.350	\N	2026-10-07 05:31:57.09665	1
4315	612	2	15.550	\N	2026-10-07 05:31:57.09665	1
4316	612	3	28.950	\N	2026-10-07 05:31:57.09665	1
4317	612	4	26.250	\N	2026-10-07 05:31:57.09665	1
4318	612	5	24.450	\N	2026-10-07 05:31:57.09665	1
4319	612	6	30.150	\N	2026-10-07 05:31:57.09665	1
4320	612	7	28.500	\N	2026-10-07 05:31:57.09665	1
4321	612	8	22.600	\N	2026-10-07 05:31:57.09665	1
4322	613	1	30.050	\N	2026-10-07 05:32:21.523935	1
4323	614	1	26.400	\N	2026-10-07 05:33:14.399352	1
4324	614	2	25.450	\N	2026-10-07 05:33:14.399352	1
4325	614	3	26.600	\N	2026-10-07 05:33:14.399352	1
4326	614	4	24.800	\N	2026-10-07 05:33:14.399352	1
4327	614	5	22.800	\N	2026-10-07 05:33:14.399352	1
4328	614	6	25.650	\N	2026-10-07 05:33:14.399352	1
4329	614	7	24.450	\N	2026-10-07 05:33:14.399352	1
4330	614	8	24.500	\N	2026-10-07 05:33:14.399352	1
4331	615	1	30.700	\N	2026-10-07 05:34:21.191417	1
4332	615	2	26.850	\N	2026-10-07 05:34:21.191417	1
4333	615	3	29.250	\N	2026-10-07 05:34:21.191417	1
4334	615	4	29.500	\N	2026-10-07 05:34:21.191417	1
4335	615	5	25.300	\N	2026-10-07 05:34:21.191417	1
4336	615	6	23.450	\N	2026-10-07 05:34:21.191417	1
4337	615	7	29.300	\N	2026-10-07 05:34:21.191417	1
4338	616	1	32.600	\N	2026-10-07 05:35:07.079636	1
4339	616	2	35.500	\N	2026-10-07 05:35:07.079636	1
4340	616	3	29.950	\N	2026-10-07 05:35:07.079636	1
4341	616	4	31.650	\N	2026-10-07 05:35:07.079636	1
4342	616	5	30.800	\N	2026-10-07 05:35:07.079636	1
4343	616	6	29.400	\N	2026-10-07 05:35:07.079636	1
4344	616	7	28.100	\N	2026-10-07 05:35:07.079636	1
4345	616	8	27.150	\N	2026-10-07 05:35:07.079636	1
4346	617	1	26.550	\N	2026-10-07 05:36:23.70505	1
4347	617	2	27.900	\N	2026-10-07 05:36:23.70505	1
4348	617	3	26.400	\N	2026-10-07 05:36:23.70505	1
4349	617	4	33.200	\N	2026-10-07 05:36:23.70505	1
4350	617	5	28.200	\N	2026-10-07 05:36:23.70505	1
4351	617	6	24.600	\N	2026-10-07 05:36:23.70505	1
4352	618	1	18.900	\N	2026-10-08 05:33:56.957957	1
4353	619	1	30.350	\N	2026-10-08 05:34:40.274215	1
4354	619	2	29.550	\N	2026-10-08 05:34:40.274215	1
4355	619	3	29.450	\N	2026-10-08 05:34:40.274215	1
4356	619	4	25.900	\N	2026-10-08 05:34:40.274215	1
4357	619	5	29.350	\N	2026-10-08 05:34:40.274215	1
4358	619	6	33.000	\N	2026-10-08 05:34:40.274215	1
4359	620	1	17.150	\N	2026-10-08 05:35:22.888374	1
4360	620	2	22.500	\N	2026-10-08 05:35:22.888374	1
4361	620	3	22.050	\N	2026-10-08 05:35:22.888374	1
4362	620	4	13.400	\N	2026-10-08 05:35:22.888374	1
4363	621	1	17.450	\N	2026-10-08 05:35:42.606911	1
4364	622	1	22.450	\N	2026-10-08 05:37:20.085905	1
4365	622	2	29.600	\N	2026-10-08 05:37:20.085905	1
4366	622	3	31.200	\N	2026-10-08 05:37:20.085905	1
4367	622	4	23.900	\N	2026-10-08 05:37:20.085905	1
4368	622	5	31.200	\N	2026-10-08 05:37:20.085905	1
4369	622	6	21.350	\N	2026-10-08 05:37:20.085905	1
4370	622	7	28.300	\N	2026-10-08 05:37:20.085905	1
4371	622	8	34.050	\N	2026-10-08 05:37:20.085905	1
4372	623	1	23.100	\N	2026-10-08 05:42:00.089663	1
4373	623	2	27.600	\N	2026-10-08 05:42:00.089663	1
4374	623	3	28.050	\N	2026-10-08 05:42:00.089663	1
4375	623	4	31.850	\N	2026-10-08 05:42:00.089663	1
4376	623	5	26.850	\N	2026-10-08 05:42:00.089663	1
4377	623	6	29.950	\N	2026-10-08 05:42:00.089663	1
4378	624	1	24.650	\N	2026-10-08 05:42:57.767373	1
4379	624	2	19.000	\N	2026-10-08 05:42:57.767373	1
4380	624	3	28.350	\N	2026-10-08 05:42:57.767373	1
4381	624	4	28.250	\N	2026-10-08 05:42:57.767373	1
4382	624	5	28.400	\N	2026-10-08 05:42:57.767373	1
4383	624	6	26.650	\N	2026-10-08 05:42:57.767373	1
4384	625	1	29.400	\N	2026-10-09 05:19:56.391503	1
4385	625	2	29.100	\N	2026-10-09 05:19:56.391503	1
4386	625	3	28.100	\N	2026-10-09 05:19:56.391503	1
4387	625	4	28.750	\N	2026-10-09 05:19:56.391503	1
4388	625	5	29.050	\N	2026-10-09 05:19:56.391503	1
4389	625	6	29.350	\N	2026-10-09 05:19:56.391503	1
4390	625	7	23.250	\N	2026-10-09 05:19:56.391503	1
4391	626	1	28.900	\N	2026-10-09 05:23:27.894698	1
4392	626	2	28.950	\N	2026-10-09 05:23:27.894698	1
4393	626	3	29.650	\N	2026-10-09 05:23:27.894698	1
4394	626	4	28.850	\N	2026-10-09 05:23:27.894698	1
4395	626	5	29.500	\N	2026-10-09 05:23:27.894698	1
4396	626	6	20.650	\N	2026-10-09 05:23:27.894698	1
4397	626	7	29.850	\N	2026-10-09 05:23:27.894698	1
4398	627	1	24.700	\N	2026-10-09 05:24:15.825204	1
4399	627	2	22.500	\N	2026-10-09 05:24:15.825204	1
4400	627	3	19.900	\N	2026-10-09 05:24:15.825204	1
4401	627	4	21.000	\N	2026-10-09 05:24:15.825204	1
4402	627	5	25.700	\N	2026-10-09 05:24:15.825204	1
4403	627	6	21.150	\N	2026-10-09 05:24:15.825204	1
4404	627	7	18.100	\N	2026-10-09 05:24:15.825204	1
4405	628	1	18.500	\N	2026-10-09 05:25:07.787644	1
4406	628	2	21.400	\N	2026-10-09 05:25:07.787644	1
4407	628	3	20.750	\N	2026-10-09 05:25:07.787644	1
4408	628	4	22.100	\N	2026-10-09 05:25:07.787644	1
4409	628	5	21.650	\N	2026-10-09 05:25:07.787644	1
4410	628	6	15.100	\N	2026-10-09 05:25:07.787644	1
4411	629	1	27.850	\N	2026-10-09 05:26:07.884466	1
4412	629	2	34.450	\N	2026-10-09 05:26:07.884466	1
4413	629	3	28.100	\N	2026-10-09 05:26:07.884466	1
4414	629	4	30.550	\N	2026-10-09 05:26:07.884466	1
4415	629	5	29.700	\N	2026-10-09 05:26:07.884466	1
4416	629	6	28.400	\N	2026-10-09 05:26:07.884466	1
4417	629	7	30.200	\N	2026-10-09 05:26:07.884466	1
4418	630	1	21.800	\N	2026-10-09 05:34:51.032264	1
4419	630	2	25.450	\N	2026-10-09 05:34:51.032264	1
4420	630	3	28.100	\N	2026-10-09 05:34:51.032264	1
4421	630	4	24.950	\N	2026-10-09 05:34:51.032264	1
4422	630	5	24.300	\N	2026-10-09 05:34:51.032264	1
4423	630	6	23.850	\N	2026-10-09 05:34:51.032264	1
4424	630	7	33.150	\N	2026-10-09 05:34:51.032264	1
4425	630	8	31.750	\N	2026-10-09 05:34:51.032264	1
4426	630	9	14.900	\N	2026-10-09 05:34:51.032264	1
4427	631	1	30.750	\N	2026-10-09 05:35:17.66762	1
4428	631	2	27.400	\N	2026-10-09 05:35:17.66762	1
4429	632	1	14.500	\N	2026-10-09 05:36:15.417611	1
4430	632	2	17.900	\N	2026-10-09 05:36:15.417611	1
4431	632	3	28.800	\N	2026-10-09 05:36:15.417611	1
4432	632	4	25.250	\N	2026-10-09 05:36:15.417611	1
4433	632	5	26.800	\N	2026-10-09 05:36:15.417611	1
4434	632	6	24.900	\N	2026-10-09 05:36:15.417611	1
4435	632	7	27.800	\N	2026-10-09 05:36:15.417611	1
4436	633	1	23.300	\N	2026-10-10 05:38:59.433443	1
4437	633	2	29.150	\N	2026-10-10 05:38:59.433443	1
4438	633	3	25.800	\N	2026-10-10 05:38:59.433443	1
4439	633	4	29.700	\N	2026-10-10 05:38:59.433443	1
4440	633	5	30.250	\N	2026-10-10 05:38:59.433443	1
4441	633	6	24.650	\N	2026-10-10 05:38:59.433443	1
4442	634	1	25.150	\N	2026-10-10 05:39:40.692559	1
4443	634	2	24.250	\N	2026-10-10 05:39:40.692559	1
4444	634	3	24.200	\N	2026-10-10 05:39:40.692559	1
4445	635	1	25.900	\N	2026-10-10 05:40:11.980139	1
4446	635	2	29.600	\N	2026-10-10 05:40:11.980139	1
4447	635	3	22.550	\N	2026-10-10 05:40:11.980139	1
4448	636	1	20.450	\N	2026-10-10 05:40:38.061065	1
4449	636	2	22.900	\N	2026-10-10 05:40:38.061065	1
4450	637	1	20.150	\N	2026-10-10 05:41:48.533339	1
4451	637	2	24.600	\N	2026-10-10 05:41:48.533339	1
4452	637	3	18.300	\N	2026-10-10 05:41:48.533339	1
4453	637	4	14.900	\N	2026-10-10 05:41:48.533339	1
4454	637	5	18.050	\N	2026-10-10 05:41:48.533339	1
4455	638	1	20.250	\N	2026-10-10 05:44:12.238154	1
4456	638	2	14.700	\N	2026-10-10 05:44:12.238154	1
4457	638	3	16.150	\N	2026-10-10 05:44:12.238154	1
4458	638	4	20.250	\N	2026-10-10 05:44:12.238154	1
4459	638	5	16.000	\N	2026-10-10 05:44:12.238154	1
4460	639	1	28.250	\N	2026-10-10 05:50:11.804627	1
4461	639	2	29.300	\N	2026-10-10 05:50:11.804627	1
4462	639	3	30.400	\N	2026-10-10 05:50:11.804627	1
4463	639	4	29.600	\N	2026-10-10 05:50:11.804627	1
4464	639	5	29.050	\N	2026-10-10 05:50:11.804627	1
4465	639	6	27.750	\N	2026-10-10 05:50:11.804627	1
4466	639	7	27.550	\N	2026-10-10 05:50:11.804627	1
4470	641	1	30.100	\N	2026-10-10 05:56:28.940819	1
4471	641	2	29.250	\N	2026-10-10 05:56:28.940819	1
4472	641	3	31.300	\N	2026-10-10 05:56:28.940819	1
4473	641	4	32.600	\N	2026-10-10 05:56:28.940819	1
4474	641	5	30.950	\N	2026-10-10 05:56:28.940819	1
4475	641	6	32.350	\N	2026-10-10 05:56:28.940819	1
4476	641	7	30.300	\N	2026-10-10 05:56:28.940819	1
4477	642	1	26.600	\N	2026-10-10 05:57:03.689535	1
4478	642	2	23.400	\N	2026-10-10 05:57:03.689535	1
4479	642	3	28.550	\N	2026-10-10 05:57:03.689535	1
4480	642	4	33.000	\N	2026-10-10 05:57:03.689535	1
4481	642	5	30.700	\N	2026-10-10 05:57:03.689535	1
4482	643	1	33.150	\N	2026-10-10 05:57:30.62659	1
4483	643	2	28.450	\N	2026-10-10 05:57:30.62659	1
4484	644	1	27.200	\N	2026-10-10 05:58:17.195512	1
4485	644	2	34.200	\N	2026-10-10 05:58:17.195512	1
4486	644	3	24.300	\N	2026-10-10 05:58:17.195512	1
4487	644	4	26.500	\N	2026-10-10 05:58:17.195512	1
4488	644	5	26.500	\N	2026-10-10 05:58:17.195512	1
4489	644	6	27.150	\N	2026-10-10 05:58:17.195512	1
4490	645	1	29.200	\N	2026-10-11 08:02:42.713412	1
4491	645	2	28.650	\N	2026-10-11 08:02:42.713412	1
4492	645	3	22.150	\N	2026-10-11 08:02:42.713412	1
4493	645	4	30.100	\N	2026-10-11 08:02:42.713412	1
4494	645	5	29.450	\N	2026-10-11 08:02:42.713412	1
4495	645	6	23.650	\N	2026-10-11 08:02:42.713412	1
4496	645	7	26.900	\N	2026-10-11 08:02:42.713412	1
4497	646	1	29.500	\N	2026-10-11 08:03:27.527774	1
4498	646	2	29.200	\N	2026-10-11 08:03:27.527774	1
4499	646	3	22.500	\N	2026-10-11 08:03:27.527774	1
4500	646	4	25.350	\N	2026-10-11 08:03:27.527774	1
4501	646	5	29.900	\N	2026-10-11 08:03:27.527774	1
4502	646	6	21.750	\N	2026-10-11 08:03:27.527774	1
4503	646	7	25.050	\N	2026-10-11 08:03:27.527774	1
4504	647	1	23.150	\N	2026-10-11 08:04:32.725364	1
4505	647	2	23.500	\N	2026-10-11 08:04:32.725364	1
4506	647	3	23.950	\N	2026-10-11 08:04:32.725364	1
4507	647	4	25.500	\N	2026-10-11 08:04:32.725364	1
4508	647	5	25.750	\N	2026-10-11 08:04:32.725364	1
4509	648	1	21.250	\N	2026-10-11 08:05:26.295781	1
4510	648	2	26.900	\N	2026-10-11 08:05:26.295781	1
4511	648	3	25.000	\N	2026-10-11 08:05:26.295781	1
4512	648	4	15.550	\N	2026-10-11 08:05:26.295781	1
4513	648	5	20.900	\N	2026-10-11 08:05:26.295781	1
4514	648	6	18.950	\N	2026-10-11 08:05:26.295781	1
4515	648	7	25.250	\N	2026-10-11 08:05:26.295781	1
4516	648	8	20.450	\N	2026-10-11 08:05:26.295781	1
4517	649	1	19.700	\N	2026-10-11 08:05:46.971164	1
4518	650	1	26.950	\N	2026-10-11 08:06:36.383308	1
4519	650	2	22.000	\N	2026-10-11 08:06:36.383308	1
4520	650	3	29.450	\N	2026-10-11 08:06:36.383308	1
4521	650	4	31.400	\N	2026-10-11 08:06:36.383308	1
4522	650	5	29.350	\N	2026-10-11 08:06:36.383308	1
4523	650	6	27.900	\N	2026-10-11 08:06:36.383308	1
4524	650	7	23.950	\N	2026-10-11 08:06:36.383308	1
4525	651	1	31.700	\N	2026-10-11 08:07:38.093703	1
4526	651	2	31.600	\N	2026-10-11 08:07:38.093703	1
4527	651	3	32.100	\N	2026-10-11 08:07:38.093703	1
4528	651	4	32.050	\N	2026-10-11 08:07:38.093703	1
4529	651	5	31.650	\N	2026-10-11 08:07:38.093703	1
4530	651	6	30.600	\N	2026-10-11 08:07:38.093703	1
4531	651	7	22.500	\N	2026-10-11 08:07:38.093703	1
4661	671	7	29.250	\N	2026-10-13 05:49:39.081719	1
4662	671	8	27.600	\N	2026-10-13 05:49:39.081719	1
4663	672	1	26.200	\N	2026-10-13 05:50:29.271855	1
4664	672	2	29.000	\N	2026-10-13 05:50:29.271855	1
4665	672	3	29.700	\N	2026-10-13 05:50:29.271855	1
4666	672	4	29.200	\N	2026-10-13 05:50:29.271855	1
4667	672	5	19.000	\N	2026-10-13 05:50:29.271855	1
4668	672	6	29.000	\N	2026-10-13 05:50:29.271855	1
4669	672	7	23.250	\N	2026-10-13 05:50:29.271855	1
4541	653	1	23.000	\N	2026-10-11 08:09:17.722094	1
4542	653	2	23.550	\N	2026-10-11 08:09:17.722094	1
4543	653	3	22.250	\N	2026-10-11 08:09:17.722094	1
4544	653	4	26.250	\N	2026-10-11 08:09:17.722094	1
4545	653	5	14.600	\N	2026-10-11 08:09:17.722094	1
4546	653	6	22.200	\N	2026-10-11 08:09:17.722094	1
4547	652	1	20.800	\N	2026-10-11 08:10:16.983888	1
4548	652	2	26.150	\N	2026-10-11 08:10:16.983888	1
4549	652	3	32.000	\N	2026-10-11 08:10:16.983888	1
4550	652	4	33.000	\N	2026-10-11 08:10:16.983888	1
4551	652	5	30.700	\N	2026-10-11 08:10:16.983888	1
4552	652	6	30.750	\N	2026-10-11 08:10:16.983888	1
4553	652	7	30.800	\N	2026-10-11 08:10:16.983888	1
4554	652	8	18.700	\N	2026-10-11 08:10:16.983888	1
4670	673	1	30.650	\N	2026-10-13 05:51:09.678404	1
4557	655	1	26.650	\N	2026-10-12 05:39:27.888172	1
4558	655	2	17.850	\N	2026-10-12 05:39:27.888172	1
4559	656	1	28.850	\N	2026-10-12 05:40:00.198818	1
4560	656	2	23.850	\N	2026-10-12 05:40:00.198818	1
4561	656	3	21.600	\N	2026-10-12 05:40:00.198818	1
4562	656	4	24.100	\N	2026-10-12 05:40:00.198818	1
4563	657	1	29.200	\N	2026-10-12 05:40:36.769552	1
4564	657	2	29.550	\N	2026-10-12 05:40:36.769552	1
4565	657	3	25.950	\N	2026-10-12 05:40:36.769552	1
4566	658	1	31.050	\N	2026-10-12 05:41:17.878233	1
4567	658	2	26.050	\N	2026-10-12 05:41:17.878233	1
4568	658	3	20.600	\N	2026-10-12 05:41:17.878233	1
4569	658	4	20.250	\N	2026-10-12 05:41:17.878233	1
4570	659	1	26.900	\N	2026-10-12 05:46:22.78145	1
4571	659	2	29.150	\N	2026-10-12 05:46:22.78145	1
4572	659	3	20.350	\N	2026-10-12 05:46:22.78145	1
4573	659	4	26.000	\N	2026-10-12 05:46:22.78145	1
4574	659	5	29.450	\N	2026-10-12 05:46:22.78145	1
4575	659	6	27.400	\N	2026-10-12 05:46:22.78145	1
4576	659	7	29.200	\N	2026-10-12 05:46:22.78145	1
4577	660	1	20.400	\N	2026-10-12 05:47:06.99287	1
4578	660	2	23.400	\N	2026-10-12 05:47:06.99287	1
4579	660	3	21.700	\N	2026-10-12 05:47:06.99287	1
4580	660	4	24.100	\N	2026-10-12 05:47:06.99287	1
4581	660	5	29.950	\N	2026-10-12 05:47:06.99287	1
4582	660	6	28.600	\N	2026-10-12 05:47:06.99287	1
4583	660	7	29.500	\N	2026-10-12 05:47:06.99287	1
4584	661	1	8.600	\N	2026-10-12 05:47:52.570368	1
4585	661	2	8.350	\N	2026-10-12 05:47:52.570368	1
4586	661	3	12.700	\N	2026-10-12 05:47:52.570368	1
4587	661	4	22.000	\N	2026-10-12 05:47:52.570368	1
4588	661	5	21.050	\N	2026-10-12 05:47:52.570368	1
4589	661	6	25.000	\N	2026-10-12 05:47:52.570368	1
4590	661	7	24.550	\N	2026-10-12 05:47:52.570368	1
4591	661	8	22.500	\N	2026-10-12 05:47:52.570368	1
4592	662	1	20.200	\N	2026-10-12 05:48:46.363919	1
4593	662	2	22.300	\N	2026-10-12 05:48:46.363919	1
4594	662	3	19.400	\N	2026-10-12 05:48:46.363919	1
4595	662	4	17.600	\N	2026-10-12 05:48:46.363919	1
4596	662	5	25.650	\N	2026-10-12 05:48:46.363919	1
4597	662	6	21.450	\N	2026-10-12 05:48:46.363919	1
4598	662	7	21.550	\N	2026-10-12 05:48:46.363919	1
4599	663	1	18.500	\N	2026-10-12 05:49:51.80563	1
4600	663	2	31.150	\N	2026-10-12 05:49:51.80563	1
4601	663	3	31.400	\N	2026-10-12 05:49:51.80563	1
4602	663	4	31.450	\N	2026-10-12 05:49:51.80563	1
4603	663	5	31.300	\N	2026-10-12 05:49:51.80563	1
4604	663	6	25.800	\N	2026-10-12 05:49:51.80563	1
4605	664	1	21.400	\N	2026-10-12 06:06:50.703258	1
4606	664	2	23.800	\N	2026-10-12 06:06:50.703258	1
4607	664	3	30.550	\N	2026-10-12 06:06:50.703258	1
4608	664	4	26.750	\N	2026-10-12 06:06:50.703258	1
4609	664	5	29.250	\N	2026-10-12 06:06:50.703258	1
4610	664	6	27.300	\N	2026-10-12 06:06:50.703258	1
4611	664	7	29.350	\N	2026-10-12 06:06:50.703258	1
4612	664	8	28.100	\N	2026-10-12 06:06:50.703258	1
4613	665	1	26.500	\N	2026-10-12 06:07:46.470475	1
4614	665	2	32.200	\N	2026-10-12 06:07:46.470475	1
4615	665	3	29.700	\N	2026-10-12 06:07:46.470475	1
4616	665	4	31.200	\N	2026-10-12 06:07:46.470475	1
4617	665	5	31.850	\N	2026-10-12 06:07:46.470475	1
4618	665	6	28.900	\N	2026-10-12 06:07:46.470475	1
4619	665	7	32.100	\N	2026-10-12 06:07:46.470475	1
4620	665	8	28.800	\N	2026-10-12 06:07:46.470475	1
4676	673	7	22.750	\N	2026-10-13 05:51:09.678404	1
4677	674	1	12.200	\N	2026-10-13 05:51:49.226725	1
4678	674	2	23.550	\N	2026-10-13 05:51:49.226725	1
4679	675	1	16.700	\N	2026-10-13 05:52:29.789101	1
4680	675	2	13.250	\N	2026-10-13 05:52:29.789101	1
4681	676	1	23.650	\N	2026-10-13 05:53:30.385221	1
4682	676	2	24.600	\N	2026-10-13 05:53:30.385221	1
4683	676	3	24.650	\N	2026-10-13 05:53:30.385221	1
4684	676	4	8.650	\N	2026-10-13 05:53:30.385221	1
4685	677	1	29.200	\N	2026-10-13 05:55:30.063991	1
4686	677	2	23.150	\N	2026-10-13 05:55:30.063991	1
4687	677	3	28.850	\N	2026-10-13 05:55:30.063991	1
4688	677	4	29.400	\N	2026-10-13 05:55:30.063991	1
4689	677	5	29.550	\N	2026-10-13 05:55:30.063991	1
4690	677	6	30.400	\N	2026-10-13 05:55:30.063991	1
4691	677	7	26.650	\N	2026-10-13 05:55:30.063991	1
4692	677	8	29.900	\N	2026-10-13 05:55:30.063991	1
4693	678	1	29.550	\N	2026-10-13 05:58:02.281663	1
4694	678	2	29.200	\N	2026-10-13 05:58:02.281663	1
4695	678	3	29.200	\N	2026-10-13 05:58:02.281663	1
4696	678	4	28.100	\N	2026-10-13 05:58:02.281663	1
4697	678	5	31.950	\N	2026-10-13 05:58:02.281663	1
4698	678	6	31.200	\N	2026-10-13 05:58:02.281663	1
4699	678	7	29.900	\N	2026-10-13 05:58:02.281663	1
4700	679	1	24.350	\N	2026-10-13 05:58:57.586743	1
4701	679	2	23.900	\N	2026-10-13 05:58:57.586743	1
4702	679	3	31.500	\N	2026-10-13 05:58:57.586743	1
4703	679	4	32.100	\N	2026-10-13 05:58:57.586743	1
4704	679	5	29.150	\N	2026-10-13 05:58:57.586743	1
4705	679	6	33.150	\N	2026-10-13 05:58:57.586743	1
4706	679	7	31.000	\N	2026-10-13 05:58:57.586743	1
4707	679	8	34.800	\N	2026-10-13 05:58:57.586743	1
4708	680	1	25.500	\N	2026-10-13 05:59:48.632338	1
4709	680	2	29.650	\N	2026-10-13 05:59:48.632338	1
4710	680	3	31.000	\N	2026-10-13 05:59:48.632338	1
4711	680	4	29.550	\N	2026-10-13 05:59:48.632338	1
4712	680	5	30.650	\N	2026-10-13 05:59:48.632338	1
4713	680	6	29.850	\N	2026-10-13 05:59:48.632338	1
4714	680	7	31.650	\N	2026-10-13 05:59:48.632338	1
4715	681	1	27.300	\N	2026-10-13 06:02:04.667344	1
4716	681	2	34.650	\N	2026-10-13 06:02:04.667344	1
4717	681	3	30.350	\N	2026-10-13 06:02:04.667344	1
4718	681	4	30.600	\N	2026-10-13 06:02:04.667344	1
4719	681	5	31.000	\N	2026-10-13 06:02:04.667344	1
4720	681	6	30.700	\N	2026-10-13 06:02:04.667344	1
4721	681	7	32.500	\N	2026-10-13 06:02:04.667344	1
4722	682	1	27.200	\N	2026-10-13 06:02:44.731436	1
4723	682	2	27.900	\N	2026-10-13 06:02:44.731436	1
4724	682	3	27.350	\N	2026-10-13 06:02:44.731436	1
4725	683	1	28.950	\N	2026-10-13 06:03:32.786141	1
4726	683	2	30.500	\N	2026-10-13 06:03:32.786141	1
4727	683	3	30.550	\N	2026-10-13 06:03:32.786141	1
4728	683	4	28.100	\N	2026-10-13 06:03:32.786141	1
4729	683	5	29.400	\N	2026-10-13 06:03:32.786141	1
4730	683	6	27.900	\N	2026-10-13 06:03:32.786141	1
4731	683	7	28.650	\N	2026-10-13 06:03:32.786141	1
4732	683	8	30.600	\N	2026-10-13 06:03:32.786141	1
4733	684	1	30.800	\N	2026-10-14 06:06:28.386207	1
4734	684	2	25.700	\N	2026-10-14 06:06:28.386207	1
4735	684	3	27.400	\N	2026-10-14 06:06:28.386207	1
4736	684	4	27.750	\N	2026-10-14 06:06:28.386207	1
4737	684	5	23.950	\N	2026-10-14 06:06:28.386207	1
4738	684	6	22.800	\N	2026-10-14 06:06:28.386207	1
4739	684	7	27.150	\N	2026-10-14 06:06:28.386207	1
4740	684	8	24.400	\N	2026-10-14 06:06:28.386207	1
4741	685	1	30.250	\N	2026-10-14 06:07:19.988366	1
4742	685	2	31.000	\N	2026-10-14 06:07:19.988366	1
4743	685	3	30.150	\N	2026-10-14 06:07:19.988366	1
4744	685	4	29.800	\N	2026-10-14 06:07:19.988366	1
4745	685	5	29.550	\N	2026-10-14 06:07:19.988366	1
4746	685	6	27.600	\N	2026-10-14 06:07:19.988366	1
4747	685	7	25.900	\N	2026-10-14 06:07:19.988366	1
4748	686	1	25.700	\N	2026-10-14 06:08:15.896225	1
4749	686	2	28.500	\N	2026-10-14 06:08:15.896225	1
4750	686	3	30.350	\N	2026-10-14 06:08:15.896225	1
4751	686	4	30.100	\N	2026-10-14 06:08:15.896225	1
4752	686	5	29.600	\N	2026-10-14 06:08:15.896225	1
4753	686	6	29.250	\N	2026-10-14 06:08:15.896225	1
4754	686	7	23.450	\N	2026-10-14 06:08:15.896225	1
4755	687	1	30.000	\N	2026-10-14 06:09:03.3994	1
4756	687	2	24.550	\N	2026-10-14 06:09:03.3994	1
4757	687	3	25.850	\N	2026-10-14 06:09:03.3994	1
4758	687	4	26.050	\N	2026-10-14 06:09:03.3994	1
4759	687	5	12.100	\N	2026-10-14 06:09:03.3994	1
4760	687	6	25.750	\N	2026-10-14 06:09:03.3994	1
4761	687	7	23.750	\N	2026-10-14 06:09:03.3994	1
4762	688	1	19.150	\N	2026-10-14 06:09:42.996215	1
4763	688	2	20.150	\N	2026-10-14 06:09:42.996215	1
4764	688	3	22.350	\N	2026-10-14 06:09:42.996215	1
4765	688	4	19.800	\N	2026-10-14 06:09:42.996215	1
4766	688	5	15.250	\N	2026-10-14 06:09:42.996215	1
4767	689	1	25.650	\N	2026-10-14 06:10:31.707869	1
4768	689	2	25.900	\N	2026-10-14 06:10:31.707869	1
4769	689	3	18.700	\N	2026-10-14 06:10:31.707869	1
4770	689	4	17.950	\N	2026-10-14 06:10:31.707869	1
4771	689	5	14.050	\N	2026-10-14 06:10:31.707869	1
4772	690	1	30.400	\N	2026-10-14 06:11:30.096003	1
4773	690	2	10.800	\N	2026-10-14 06:11:30.096003	1
4774	690	3	30.750	\N	2026-10-14 06:11:30.096003	1
4775	690	4	29.200	\N	2026-10-14 06:11:30.096003	1
4776	690	5	18.250	\N	2026-10-14 06:11:30.096003	1
4777	690	6	25.850	\N	2026-10-14 06:11:30.096003	1
4778	690	7	29.000	\N	2026-10-14 06:11:30.096003	1
4779	690	8	29.050	\N	2026-10-14 06:11:30.096003	1
4780	690	9	29.600	\N	2026-10-14 06:11:30.096003	1
4781	691	1	28.600	\N	2026-10-14 06:12:53.24747	1
4782	691	2	28.700	\N	2026-10-14 06:12:53.24747	1
4783	691	3	31.200	\N	2026-10-14 06:12:53.24747	1
4784	691	4	29.300	\N	2026-10-14 06:12:53.24747	1
4785	691	5	28.850	\N	2026-10-14 06:12:53.24747	1
4786	691	6	28.150	\N	2026-10-14 06:12:53.24747	1
4787	691	7	29.400	\N	2026-10-14 06:12:53.24747	1
4788	692	1	29.300	\N	2026-10-14 06:15:57.087243	1
4789	692	2	32.050	\N	2026-10-14 06:15:57.087243	1
4790	692	3	32.250	\N	2026-10-14 06:15:57.087243	1
4791	692	4	28.100	\N	2026-10-14 06:15:57.087243	1
4792	692	5	30.500	\N	2026-10-14 06:15:57.087243	1
4793	692	6	27.850	\N	2026-10-14 06:15:57.087243	1
4794	692	7	30.150	\N	2026-10-14 06:15:57.087243	1
4795	692	8	32.350	\N	2026-10-14 06:15:57.087243	1
4796	693	1	30.500	\N	2026-10-14 06:17:00.389353	1
4797	693	2	22.850	\N	2026-10-14 06:17:00.389353	1
4798	693	3	29.400	\N	2026-10-14 06:17:00.389353	1
4799	693	4	28.750	\N	2026-10-14 06:17:00.389353	1
4800	693	5	28.450	\N	2026-10-14 06:17:00.389353	1
4801	693	6	29.100	\N	2026-10-14 06:17:00.389353	1
4802	693	7	30.900	\N	2026-10-14 06:17:00.389353	1
4803	694	1	30.350	\N	2026-10-14 06:17:51.508161	1
4804	694	2	25.700	\N	2026-10-14 06:17:51.508161	1
4805	694	3	30.400	\N	2026-10-14 06:17:51.508161	1
4806	694	4	33.050	\N	2026-10-14 06:17:51.508161	1
4807	694	5	32.250	\N	2026-10-14 06:17:51.508161	1
4808	694	6	33.550	\N	2026-10-14 06:17:51.508161	1
4809	694	7	31.100	\N	2026-10-14 06:17:51.508161	1
4814	696	1	28.550	\N	2026-10-14 06:19:04.742219	1
4815	696	2	19.750	\N	2026-10-14 06:19:04.742219	1
4816	696	3	31.650	\N	2026-10-14 06:19:04.742219	1
4817	696	4	30.650	\N	2026-10-14 06:19:04.742219	1
4818	696	5	29.550	\N	2026-10-14 06:19:04.742219	1
4819	697	1	30.950	\N	2026-10-14 06:19:49.500422	1
4820	697	2	30.000	\N	2026-10-14 06:19:49.500422	1
4821	697	3	27.250	\N	2026-10-14 06:19:49.500422	1
4822	697	4	30.050	\N	2026-10-14 06:19:49.500422	1
4823	697	5	29.700	\N	2026-10-14 06:19:49.500422	1
4824	697	6	25.950	\N	2026-10-14 06:19:49.500422	1
4825	697	7	29.600	\N	2026-10-14 06:19:49.500422	1
4826	697	8	30.800	\N	2026-10-14 06:19:49.500422	1
4827	695	1	21.700	\N	2026-10-14 06:21:05.92364	1
4828	695	2	23.150	\N	2026-10-14 06:21:05.92364	1
4829	695	3	26.400	\N	2026-10-14 06:21:05.92364	1
4830	695	4	23.000	\N	2026-10-14 06:21:05.92364	1
4831	698	1	23.700	\N	2026-10-15 05:13:21.073943	1
4832	698	2	18.100	\N	2026-10-15 05:13:21.073943	1
4833	698	3	25.350	\N	2026-10-15 05:13:21.073943	1
4834	698	4	26.100	\N	2026-10-15 05:13:21.073943	1
4835	698	5	28.650	\N	2026-10-15 05:13:21.073943	1
4836	698	6	23.850	\N	2026-10-15 05:13:21.073943	1
4837	698	7	24.950	\N	2026-10-15 05:13:21.073943	1
4838	699	1	31.100	\N	2026-10-15 05:14:20.980552	1
4839	699	2	29.300	\N	2026-10-15 05:14:20.980552	1
4840	699	3	29.750	\N	2026-10-15 05:14:20.980552	1
4841	699	4	29.850	\N	2026-10-15 05:14:20.980552	1
4842	699	5	29.550	\N	2026-10-15 05:14:20.980552	1
4843	699	6	29.500	\N	2026-10-15 05:14:20.980552	1
4844	699	7	26.350	\N	2026-10-15 05:14:20.980552	1
4845	699	8	27.500	\N	2026-10-15 05:14:20.980552	1
4846	700	1	30.500	\N	2026-10-15 05:14:57.671458	1
4847	701	1	25.050	\N	2026-10-15 05:15:45.073516	1
4848	701	2	16.250	\N	2026-10-15 05:15:45.073516	1
4849	701	3	29.150	\N	2026-10-15 05:15:45.073516	1
4850	701	4	29.900	\N	2026-10-15 05:15:45.073516	1
4851	701	5	32.300	\N	2026-10-15 05:15:45.073516	1
4852	702	1	30.650	\N	2026-10-15 05:19:25.679285	1
4853	702	2	28.050	\N	2026-10-15 05:19:25.679285	1
4854	702	3	29.900	\N	2026-10-15 05:19:25.679285	1
4855	702	4	29.450	\N	2026-10-15 05:19:25.679285	1
4856	702	5	16.150	\N	2026-10-15 05:19:25.679285	1
4857	702	6	29.800	\N	2026-10-15 05:19:25.679285	1
4858	702	7	26.500	\N	2026-10-15 05:19:25.679285	1
4859	703	1	20.850	\N	2026-10-15 05:21:30.294289	1
4860	703	2	24.950	\N	2026-10-15 05:21:30.294289	1
4861	703	3	22.700	\N	2026-10-15 05:21:30.294289	1
4862	703	4	18.800	\N	2026-10-15 05:21:30.294289	1
4863	704	1	21.850	\N	2026-10-15 05:22:17.088326	1
4864	704	2	26.150	\N	2026-10-15 05:22:17.088326	1
4865	704	3	26.550	\N	2026-10-15 05:22:17.088326	1
4866	704	4	22.750	\N	2026-10-15 05:22:17.088326	1
4867	704	5	28.550	\N	2026-10-15 05:22:17.088326	1
4868	705	1	30.300	\N	2026-10-15 05:23:05.510666	1
4869	705	2	28.700	\N	2026-10-15 05:23:05.510666	1
4870	705	3	28.850	\N	2026-10-15 05:23:05.510666	1
4871	705	4	29.400	\N	2026-10-15 05:23:05.510666	1
4872	705	5	29.300	\N	2026-10-15 05:23:05.510666	1
4873	705	6	30.450	\N	2026-10-15 05:23:05.510666	1
4874	705	7	27.150	\N	2026-10-15 05:23:05.510666	1
4875	705	8	26.400	\N	2026-10-15 05:23:05.510666	1
4876	706	1	26.250	\N	2026-10-15 05:23:56.947109	1
4877	706	2	29.300	\N	2026-10-15 05:23:56.947109	1
4878	706	3	32.250	\N	2026-10-15 05:23:56.947109	1
4879	706	4	25.200	\N	2026-10-15 05:23:56.947109	1
4880	706	5	33.550	\N	2026-10-15 05:23:56.947109	1
4881	706	6	27.750	\N	2026-10-15 05:23:56.947109	1
4882	706	7	28.000	\N	2026-10-15 05:23:56.947109	1
4883	707	1	29.950	\N	2026-10-15 05:25:32.108483	1
4884	707	2	31.300	\N	2026-10-15 05:25:32.108483	1
4885	707	3	31.000	\N	2026-10-15 05:25:32.108483	1
4886	707	4	31.200	\N	2026-10-15 05:25:32.108483	1
4887	707	5	30.700	\N	2026-10-15 05:25:32.108483	1
4888	707	6	30.400	\N	2026-10-15 05:25:32.108483	1
4889	707	7	30.950	\N	2026-10-15 05:25:32.108483	1
4890	707	8	25.450	\N	2026-10-15 05:25:32.108483	1
4891	708	1	31.050	\N	2026-10-15 05:26:31.66149	1
4892	708	2	24.000	\N	2026-10-15 05:26:31.66149	1
4893	708	3	31.050	\N	2026-10-15 05:26:31.66149	1
4894	708	4	31.900	\N	2026-10-15 05:26:31.66149	1
4895	708	5	33.050	\N	2026-10-15 05:26:31.66149	1
4896	708	6	33.250	\N	2026-10-15 05:26:31.66149	1
4897	708	7	31.400	\N	2026-10-15 05:26:31.66149	1
4898	708	8	32.350	\N	2026-10-15 05:26:31.66149	1
4899	709	1	31.200	\N	2026-10-15 05:27:20.894004	1
4900	709	2	29.850	\N	2026-10-15 05:27:20.894004	1
4901	709	3	30.350	\N	2026-10-15 05:27:20.894004	1
4902	709	4	30.200	\N	2026-10-15 05:27:20.894004	1
4903	709	5	31.300	\N	2026-10-15 05:27:20.894004	1
4904	709	6	29.550	\N	2026-10-15 05:27:20.894004	1
4905	709	7	32.050	\N	2026-10-15 05:27:20.894004	1
4906	710	1	23.750	\N	2026-10-15 05:27:52.968605	1
4907	710	2	23.000	\N	2026-10-15 05:27:52.968605	1
4908	710	3	22.650	\N	2026-10-15 05:27:52.968605	1
4909	711	1	25.950	\N	2026-10-15 05:29:17.090635	1
4910	711	2	22.850	\N	2026-10-15 05:29:17.090635	1
4911	711	3	20.550	\N	2026-10-15 05:29:17.090635	1
4912	711	4	27.750	\N	2026-10-15 05:29:17.090635	1
4913	711	5	22.950	\N	2026-10-15 05:29:17.090635	1
4914	711	6	31.350	\N	2026-10-15 05:29:17.090635	1
4915	711	7	31.300	\N	2026-10-15 05:29:17.090635	1
4916	712	1	30.600	\N	2026-10-15 05:30:06.690799	1
4917	712	2	28.050	\N	2026-10-15 05:30:06.690799	1
4918	712	3	29.050	\N	2026-10-15 05:30:06.690799	1
4919	712	4	27.600	\N	2026-10-15 05:30:06.690799	1
4920	712	5	28.900	\N	2026-10-15 05:30:06.690799	1
4921	712	6	30.350	\N	2026-10-15 05:30:06.690799	1
4922	712	7	27.600	\N	2026-10-15 05:30:06.690799	1
4923	712	8	29.400	\N	2026-10-15 05:30:06.690799	1
4924	713	1	28.200	\N	2026-10-16 06:08:03.178275	1
4925	713	2	28.700	\N	2026-10-16 06:08:03.178275	1
4926	713	3	23.250	\N	2026-10-16 06:08:03.178275	1
4927	713	4	25.000	\N	2026-10-16 06:08:03.178275	1
4928	713	5	23.700	\N	2026-10-16 06:08:03.178275	1
4929	713	6	28.050	\N	2026-10-16 06:08:03.178275	1
4930	713	7	25.550	\N	2026-10-16 06:08:03.178275	1
4931	713	8	24.900	\N	2026-10-16 06:08:03.178275	1
4932	714	1	27.700	\N	2026-10-16 06:09:00.262245	1
4933	714	2	30.050	\N	2026-10-16 06:09:00.262245	1
4934	714	3	30.400	\N	2026-10-16 06:09:00.262245	1
4935	714	4	27.200	\N	2026-10-16 06:09:00.262245	1
4936	714	5	27.400	\N	2026-10-16 06:09:00.262245	1
4937	714	6	31.200	\N	2026-10-16 06:09:00.262245	1
4938	714	7	32.000	\N	2026-10-16 06:09:00.262245	1
4939	714	8	24.400	\N	2026-10-16 06:09:00.262245	1
4940	715	1	30.850	\N	2026-10-16 06:09:46.587612	1
4941	715	2	27.750	\N	2026-10-16 06:09:46.587612	1
4942	715	3	31.650	\N	2026-10-16 06:09:46.587612	1
4943	715	4	29.300	\N	2026-10-16 06:09:46.587612	1
4944	715	5	22.800	\N	2026-10-16 06:09:46.587612	1
4945	715	6	29.200	\N	2026-10-16 06:09:46.587612	1
4946	715	7	31.200	\N	2026-10-16 06:09:46.587612	1
4947	715	8	23.750	\N	2026-10-16 06:09:46.587612	1
4948	716	1	17.050	\N	2026-10-16 06:10:18.778107	1
4949	716	2	29.700	\N	2026-10-16 06:10:18.778107	1
4950	716	3	31.250	\N	2026-10-16 06:10:18.778107	1
4951	716	4	22.200	\N	2026-10-16 06:10:18.778107	1
4952	716	5	30.900	\N	2026-10-16 06:10:18.778107	1
4953	716	6	20.000	\N	2026-10-16 06:10:18.778107	1
4954	717	1	17.150	\N	2026-10-16 06:10:48.907811	1
4955	717	2	25.500	\N	2026-10-16 06:10:48.907811	1
4956	717	3	20.000	\N	2026-10-16 06:10:48.907811	1
4957	717	4	22.400	\N	2026-10-16 06:10:48.907811	1
4958	718	1	18.700	\N	2026-10-16 06:11:43.999604	1
4959	718	2	22.450	\N	2026-10-16 06:11:43.999604	1
4960	718	3	16.550	\N	2026-10-16 06:11:43.999604	1
4961	718	4	24.550	\N	2026-10-16 06:11:43.999604	1
4962	718	5	24.150	\N	2026-10-16 06:11:43.999604	1
4963	718	6	19.850	\N	2026-10-16 06:11:43.999604	1
4964	719	1	30.350	\N	2026-10-16 06:12:32.96459	1
4965	719	2	29.700	\N	2026-10-16 06:12:32.96459	1
4966	719	3	30.100	\N	2026-10-16 06:12:32.96459	1
4967	719	4	30.550	\N	2026-10-16 06:12:32.96459	1
4968	719	5	22.300	\N	2026-10-16 06:12:32.96459	1
4969	719	6	29.750	\N	2026-10-16 06:12:32.96459	1
4970	719	7	30.750	\N	2026-10-16 06:12:32.96459	1
4971	719	8	28.900	\N	2026-10-16 06:12:32.96459	1
4972	720	1	32.250	\N	2026-10-16 06:13:27.710619	1
4973	720	2	31.450	\N	2026-10-16 06:13:27.710619	1
4974	720	3	27.350	\N	2026-10-16 06:13:27.710619	1
4975	720	4	30.300	\N	2026-10-16 06:13:27.710619	1
4976	720	5	28.500	\N	2026-10-16 06:13:27.710619	1
4977	720	6	28.650	\N	2026-10-16 06:13:27.710619	1
4978	720	7	28.900	\N	2026-10-16 06:13:27.710619	1
4979	721	1	23.100	\N	2026-10-16 06:14:21.507637	1
4980	721	2	30.550	\N	2026-10-16 06:14:21.507637	1
4981	721	3	30.300	\N	2026-10-16 06:14:21.507637	1
4982	721	4	29.300	\N	2026-10-16 06:14:21.507637	1
4983	721	5	29.900	\N	2026-10-16 06:14:21.507637	1
4984	721	6	30.750	\N	2026-10-16 06:14:21.507637	1
4985	721	7	30.600	\N	2026-10-16 06:14:21.507637	1
4986	721	8	30.450	\N	2026-10-16 06:14:21.507637	1
4987	722	1	25.500	\N	2026-10-16 06:15:01.525946	1
4988	722	2	32.000	\N	2026-10-16 06:15:01.525946	1
4989	722	3	31.550	\N	2026-10-16 06:15:01.525946	1
4990	722	4	30.900	\N	2026-10-16 06:15:01.525946	1
4991	722	5	32.000	\N	2026-10-16 06:15:01.525946	1
4992	722	6	30.550	\N	2026-10-16 06:15:01.525946	1
4993	722	7	31.500	\N	2026-10-16 06:15:01.525946	1
4994	722	8	32.400	\N	2026-10-16 06:15:01.525946	1
4995	723	1	24.100	\N	2026-10-16 06:15:44.095828	1
4996	723	2	17.900	\N	2026-10-16 06:15:44.095828	1
4997	723	3	24.350	\N	2026-10-16 06:15:44.095828	1
4998	723	4	24.550	\N	2026-10-16 06:15:44.095828	1
4999	724	1	27.400	\N	2026-10-16 06:16:42.22741	1
5000	724	2	26.550	\N	2026-10-16 06:16:42.22741	1
5001	724	3	25.950	\N	2026-10-16 06:16:42.22741	1
5002	724	4	27.600	\N	2026-10-16 06:16:42.22741	1
5003	724	5	16.050	\N	2026-10-16 06:16:42.22741	1
5004	724	6	24.100	\N	2026-10-16 06:16:42.22741	1
5005	724	7	27.650	\N	2026-10-16 06:16:42.22741	1
5006	724	8	18.250	\N	2026-10-16 06:16:42.22741	1
5007	725	1	30.300	\N	2026-10-16 06:17:42.607819	1
5008	725	2	27.650	\N	2026-10-16 06:17:42.607819	1
5009	725	3	29.750	\N	2026-10-16 06:17:42.607819	1
5010	725	4	26.600	\N	2026-10-16 06:17:42.607819	1
5011	725	5	24.950	\N	2026-10-16 06:17:42.607819	1
5012	725	6	23.550	\N	2026-10-16 06:17:42.607819	1
5013	725	7	27.400	\N	2026-10-16 06:17:42.607819	1
5014	725	8	29.450	\N	2026-10-16 06:17:42.607819	1
5015	726	1	17.500	\N	2026-10-17 05:22:15.297385	1
5016	726	2	30.350	\N	2026-10-17 05:22:15.297385	1
5017	726	3	27.400	\N	2026-10-17 05:22:15.297385	1
5018	726	4	21.750	\N	2026-10-17 05:22:15.297385	1
5019	726	5	25.550	\N	2026-10-17 05:22:15.297385	1
5020	726	6	26.750	\N	2026-10-17 05:22:15.297385	1
5021	726	7	24.900	\N	2026-10-17 05:22:15.297385	1
5022	727	1	23.700	\N	2026-10-17 05:23:04.741434	1
5023	727	2	29.500	\N	2026-10-17 05:23:04.741434	1
5024	727	3	27.850	\N	2026-10-17 05:23:04.741434	1
5025	727	4	29.450	\N	2026-10-17 05:23:04.741434	1
5026	727	5	20.000	\N	2026-10-17 05:23:04.741434	1
5027	727	6	29.450	\N	2026-10-17 05:23:04.741434	1
5028	727	7	26.950	\N	2026-10-17 05:23:04.741434	1
5029	728	1	33.150	\N	2026-10-17 05:23:49.325815	1
5030	728	2	32.050	\N	2026-10-17 05:23:49.325815	1
5031	728	3	33.050	\N	2026-10-17 05:23:49.325815	1
5032	728	4	30.800	\N	2026-10-17 05:23:49.325815	1
5033	728	5	22.450	\N	2026-10-17 05:23:49.325815	1
5034	728	6	27.550	\N	2026-10-17 05:23:49.325815	1
5035	728	7	20.900	\N	2026-10-17 05:23:49.325815	1
5036	729	1	28.750	\N	2026-10-17 05:25:28.880338	1
5037	729	2	24.450	\N	2026-10-17 05:25:28.880338	1
5038	729	3	34.200	\N	2026-10-17 05:25:28.880338	1
5039	729	4	28.900	\N	2026-10-17 05:25:28.880338	1
5040	730	1	22.200	\N	2026-10-17 05:26:09.403038	1
5041	730	2	22.000	\N	2026-10-17 05:26:09.403038	1
5042	730	3	18.650	\N	2026-10-17 05:26:09.403038	1
5043	730	4	10.700	\N	2026-10-17 05:26:09.403038	1
5044	731	1	19.750	\N	2026-10-17 05:26:50.207227	1
5045	731	2	14.250	\N	2026-10-17 05:26:50.207227	1
5046	731	3	14.850	\N	2026-10-17 05:26:50.207227	1
5047	731	4	15.350	\N	2026-10-17 05:26:50.207227	1
5048	732	1	20.800	\N	2026-10-17 05:27:36.664638	1
5049	732	2	23.400	\N	2026-10-17 05:27:36.664638	1
5050	732	3	27.900	\N	2026-10-17 05:27:36.664638	1
5051	732	4	27.350	\N	2026-10-17 05:27:36.664638	1
5052	732	5	29.000	\N	2026-10-17 05:27:36.664638	1
5053	732	6	28.400	\N	2026-10-17 05:27:36.664638	1
5054	732	7	28.000	\N	2026-10-17 05:27:36.664638	1
5055	733	1	28.150	\N	2026-10-17 05:28:44.430083	1
5056	733	2	23.050	\N	2026-10-17 05:28:44.430083	1
5057	733	3	29.250	\N	2026-10-17 05:28:44.430083	1
5058	733	4	30.550	\N	2026-10-17 05:28:44.430083	1
5059	733	5	27.000	\N	2026-10-17 05:28:44.430083	1
5060	734	1	31.150	\N	2026-10-17 05:30:02.495828	1
5061	734	2	31.900	\N	2026-10-17 05:30:02.495828	1
5062	734	3	19.050	\N	2026-10-17 05:30:02.495828	1
5063	734	4	30.900	\N	2026-10-17 05:30:02.495828	1
5064	734	5	31.300	\N	2026-10-17 05:30:02.495828	1
5065	734	6	29.200	\N	2026-10-17 05:30:02.495828	1
5066	734	7	21.200	\N	2026-10-17 05:30:02.495828	1
5067	734	8	30.200	\N	2026-10-17 05:30:02.495828	1
5068	735	1	32.450	\N	2026-10-17 05:30:47.462039	1
5069	735	2	20.900	\N	2026-10-17 05:30:47.462039	1
5070	735	3	24.750	\N	2026-10-17 05:30:47.462039	1
5071	735	4	31.950	\N	2026-10-17 05:30:47.462039	1
5072	735	5	31.750	\N	2026-10-17 05:30:47.462039	1
5073	735	6	31.700	\N	2026-10-17 05:30:47.462039	1
5074	735	7	33.000	\N	2026-10-17 05:30:47.462039	1
5075	735	8	32.550	\N	2026-10-17 05:30:47.462039	1
5076	736	1	37.700	\N	2026-10-17 05:32:26.342231	1
5077	736	2	33.750	\N	2026-10-17 05:32:26.342231	1
5078	736	3	34.550	\N	2026-10-17 05:32:26.342231	1
5079	736	4	33.650	\N	2026-10-17 05:32:26.342231	1
5080	736	5	33.500	\N	2026-10-17 05:32:26.342231	1
5081	736	6	31.450	\N	2026-10-17 05:32:26.342231	1
5082	736	7	32.750	\N	2026-10-17 05:32:26.342231	1
5083	736	8	32.950	\N	2026-10-17 05:32:26.342231	1
5084	737	1	21.150	\N	2026-10-17 05:34:02.149511	1
5085	737	2	27.550	\N	2026-10-17 05:34:02.149511	1
5086	738	1	26.550	\N	2026-10-17 05:34:46.528018	1
5087	738	2	24.600	\N	2026-10-17 05:34:46.528018	1
5088	738	3	24.000	\N	2026-10-17 05:34:46.528018	1
5089	739	1	29.350	\N	2026-10-17 05:36:01.418814	1
5090	739	2	28.900	\N	2026-10-17 05:36:01.418814	1
5091	739	3	28.950	\N	2026-10-17 05:36:01.418814	1
5092	739	4	29.250	\N	2026-10-17 05:36:01.418814	1
5093	739	5	28.900	\N	2026-10-17 05:36:01.418814	1
5094	739	6	30.450	\N	2026-10-17 05:36:01.418814	1
5095	740	1	23.250	\N	2026-10-19 07:13:58.806161	1
5096	740	2	23.050	\N	2026-10-19 07:13:58.806161	1
5097	740	3	25.300	\N	2026-10-19 07:13:58.806161	1
5098	740	4	27.950	\N	2026-10-19 07:13:58.806161	1
5099	740	5	18.800	\N	2026-10-19 07:13:58.806161	1
5100	740	6	25.050	\N	2026-10-19 07:13:58.806161	1
5101	740	7	25.800	\N	2026-10-19 07:13:58.806161	1
5102	740	8	24.200	\N	2026-10-19 07:13:58.806161	1
5111	742	1	29.250	\N	2026-10-19 07:24:16.608197	1
5112	742	2	29.350	\N	2026-10-19 07:24:16.608197	1
5113	742	3	22.300	\N	2026-10-19 07:24:16.608197	1
5114	742	4	29.450	\N	2026-10-19 07:24:16.608197	1
5115	742	5	31.050	\N	2026-10-19 07:24:16.608197	1
5116	742	6	31.150	\N	2026-10-19 07:24:16.608197	1
5117	742	7	29.600	\N	2026-10-19 07:24:16.608197	1
5118	742	8	29.050	\N	2026-10-19 07:24:16.608197	1
5119	743	1	29.750	\N	2026-10-19 07:25:10.488846	1
5120	743	2	30.500	\N	2026-10-19 07:25:10.488846	1
5121	743	3	28.350	\N	2026-10-19 07:25:10.488846	1
5122	743	4	28.800	\N	2026-10-19 07:25:10.488846	1
5123	743	5	26.150	\N	2026-10-19 07:25:10.488846	1
5124	743	6	26.100	\N	2026-10-19 07:25:10.488846	1
5125	743	7	24.300	\N	2026-10-19 07:25:10.488846	1
5126	743	8	29.400	\N	2026-10-19 07:25:10.488846	1
5127	744	1	29.300	\N	2026-10-19 07:26:16.633513	1
5128	744	2	29.450	\N	2026-10-19 07:26:16.633513	1
5129	744	3	30.200	\N	2026-10-19 07:26:16.633513	1
5130	744	4	28.950	\N	2026-10-19 07:26:16.633513	1
5131	744	5	26.200	\N	2026-10-19 07:26:16.633513	1
5132	744	6	22.350	\N	2026-10-19 07:26:16.633513	1
5133	744	7	29.700	\N	2026-10-19 07:26:16.633513	1
5134	744	8	28.750	\N	2026-10-19 07:26:16.633513	1
5135	744	9	21.550	\N	2026-10-19 07:26:16.633513	1
5136	745	1	24.300	\N	2026-10-19 07:27:04.62914	1
5137	745	2	21.450	\N	2026-10-19 07:27:04.62914	1
5138	745	3	19.350	\N	2026-10-19 07:27:04.62914	1
5139	745	4	26.600	\N	2026-10-19 07:27:04.62914	1
5140	746	1	24.850	\N	2026-10-19 07:27:51.530922	1
5141	746	2	22.600	\N	2026-10-19 07:27:51.530922	1
5142	746	3	22.800	\N	2026-10-19 07:27:51.530922	1
5143	746	4	19.050	\N	2026-10-19 07:27:51.530922	1
5144	746	5	19.400	\N	2026-10-19 07:27:51.530922	1
5145	746	6	14.450	\N	2026-10-19 07:27:51.530922	1
5146	747	1	17.400	\N	2026-10-19 07:28:36.979627	1
5147	747	2	19.650	\N	2026-10-19 07:28:36.979627	1
5148	747	3	19.150	\N	2026-10-19 07:28:36.979627	1
5149	747	4	17.750	\N	2026-10-19 07:28:36.979627	1
5150	748	1	29.750	\N	2026-10-19 07:29:32.935526	1
5151	748	2	30.150	\N	2026-10-19 07:29:32.935526	1
5152	748	3	23.850	\N	2026-10-19 07:29:32.935526	1
5153	748	4	25.950	\N	2026-10-19 07:29:32.935526	1
5154	748	5	30.250	\N	2026-10-19 07:29:32.935526	1
5155	748	6	29.150	\N	2026-10-19 07:29:32.935526	1
5156	748	7	29.300	\N	2026-10-19 07:29:32.935526	1
5157	748	8	29.150	\N	2026-10-19 07:29:32.935526	1
5158	749	1	27.850	\N	2026-10-19 07:30:31.504049	1
5159	749	2	26.300	\N	2026-10-19 07:30:31.504049	1
5160	749	3	25.600	\N	2026-10-19 07:30:31.504049	1
5161	749	4	22.950	\N	2026-10-19 07:30:31.504049	1
5162	749	5	24.700	\N	2026-10-19 07:30:31.504049	1
5163	749	6	27.950	\N	2026-10-19 07:30:31.504049	1
5164	749	7	23.900	\N	2026-10-19 07:30:31.504049	1
5165	749	8	25.350	\N	2026-10-19 07:30:31.504049	1
5166	750	1	29.150	\N	2026-10-19 07:31:24.63917	1
5167	750	2	29.600	\N	2026-10-19 07:31:24.63917	1
5168	750	3	33.300	\N	2026-10-19 07:31:24.63917	1
5169	750	4	31.800	\N	2026-10-19 07:31:24.63917	1
5170	750	5	29.800	\N	2026-10-19 07:31:24.63917	1
5171	750	6	30.250	\N	2026-10-19 07:31:24.63917	1
5172	750	7	21.300	\N	2026-10-19 07:31:24.63917	1
5173	750	8	29.250	\N	2026-10-19 07:31:24.63917	1
5174	751	1	30.200	\N	2026-10-19 07:32:14.517041	1
5175	751	2	30.300	\N	2026-10-19 07:32:14.517041	1
5176	751	3	19.900	\N	2026-10-19 07:32:14.517041	1
5177	751	4	31.200	\N	2026-10-19 07:32:14.517041	1
5178	751	5	30.950	\N	2026-10-19 07:32:14.517041	1
5179	751	6	29.650	\N	2026-10-19 07:32:14.517041	1
5180	751	7	29.700	\N	2026-10-19 07:32:14.517041	1
5181	751	8	31.000	\N	2026-10-19 07:32:14.517041	1
5182	751	9	17.200	\N	2026-10-19 07:32:14.517041	1
5183	752	1	31.800	\N	2026-10-19 07:33:05.624927	1
5184	752	2	29.000	\N	2026-10-19 07:33:05.624927	1
5185	752	3	28.850	\N	2026-10-19 07:33:05.624927	1
5186	752	4	29.700	\N	2026-10-19 07:33:05.624927	1
5187	752	5	29.050	\N	2026-10-19 07:33:05.624927	1
5188	753	1	26.350	\N	2026-10-19 07:33:42.384211	1
5189	753	2	12.550	\N	2026-10-19 07:33:42.384211	1
5190	754	1	23.950	\N	2026-10-19 07:34:45.282949	1
5191	754	2	24.000	\N	2026-10-19 07:34:45.282949	1
5192	754	3	18.200	\N	2026-10-19 07:34:45.282949	1
5193	754	4	21.400	\N	2026-10-19 07:34:45.282949	1
5194	754	5	21.000	\N	2026-10-19 07:34:45.282949	1
5195	754	6	21.000	\N	2026-10-19 07:34:45.282949	1
5196	754	7	15.900	\N	2026-10-19 07:34:45.282949	1
5197	754	8	16.100	\N	2026-10-19 07:34:45.282949	1
5198	755	1	28.800	\N	2026-10-19 07:35:35.846942	1
5199	755	2	16.900	\N	2026-10-19 07:35:35.846942	1
5200	755	3	26.550	\N	2026-10-19 07:35:35.846942	1
5201	755	4	28.400	\N	2026-10-19 07:35:35.846942	1
5202	755	5	26.000	\N	2026-10-19 07:35:35.846942	1
5203	755	6	27.150	\N	2026-10-19 07:35:35.846942	1
5204	756	1	30.100	\N	2026-10-19 07:36:28.119469	1
5205	756	2	27.450	\N	2026-10-19 07:36:28.119469	1
5206	756	3	26.200	\N	2026-10-19 07:36:28.119469	1
5207	756	4	30.200	\N	2026-10-19 07:36:28.119469	1
5208	756	5	31.750	\N	2026-10-19 07:36:28.119469	1
5209	756	6	32.750	\N	2026-10-19 07:36:28.119469	1
5210	756	7	24.500	\N	2026-10-19 07:36:28.119469	1
5211	756	8	29.500	\N	2026-10-19 07:36:28.119469	1
5212	757	1	25.300	\N	2026-10-19 07:50:28.807342	1
5213	757	2	25.400	\N	2026-10-19 07:50:28.807342	1
5214	757	3	24.350	\N	2026-10-19 07:50:28.807342	1
5215	757	4	24.500	\N	2026-10-19 07:50:28.807342	1
5216	757	5	24.600	\N	2026-10-19 07:50:28.807342	1
5217	757	6	13.100	\N	2026-10-19 07:50:28.807342	1
5218	757	7	24.000	\N	2026-10-19 07:50:28.807342	1
5219	757	8	25.150	\N	2026-10-19 07:50:28.807342	1
5220	758	1	29.550	\N	2026-10-19 07:51:44.378677	1
5221	758	2	22.650	\N	2026-10-19 07:51:44.378677	1
5222	758	3	27.900	\N	2026-10-19 07:51:44.378677	1
5223	758	4	23.550	\N	2026-10-19 07:51:44.378677	1
5224	758	5	30.750	\N	2026-10-19 07:51:44.378677	1
5225	758	6	29.200	\N	2026-10-19 07:51:44.378677	1
5226	758	7	29.400	\N	2026-10-19 07:51:44.378677	1
5227	758	8	27.500	\N	2026-10-19 07:51:44.378677	1
5228	759	1	25.700	\N	2026-10-19 07:52:32.399347	1
5229	759	2	27.100	\N	2026-10-19 07:52:32.399347	1
5230	759	3	17.000	\N	2026-10-19 07:52:32.399347	1
5231	759	4	26.950	\N	2026-10-19 07:52:32.399347	1
5232	759	5	28.650	\N	2026-10-19 07:52:32.399347	1
5233	759	6	22.100	\N	2026-10-19 07:52:32.399347	1
5234	759	7	18.650	\N	2026-10-19 07:52:32.399347	1
5235	759	8	32.100	\N	2026-10-19 07:52:32.399347	1
5236	760	1	29.500	\N	2026-10-19 07:53:04.800123	1
5237	760	2	31.800	\N	2026-10-19 07:53:04.800123	1
5238	760	3	30.750	\N	2026-10-19 07:53:04.800123	1
5239	760	4	31.450	\N	2026-10-19 07:53:04.800123	1
5240	761	1	26.900	\N	2026-10-19 07:53:55.300372	1
5241	761	2	23.400	\N	2026-10-19 07:53:55.300372	1
5242	761	3	24.100	\N	2026-10-19 07:53:55.300372	1
5243	762	1	11.900	\N	2026-10-19 07:54:43.246088	1
5244	762	2	24.100	\N	2026-10-19 07:54:43.246088	1
5245	762	3	18.750	\N	2026-10-19 07:54:43.246088	1
5246	762	4	16.400	\N	2026-10-19 07:54:43.246088	1
5247	762	5	23.600	\N	2026-10-19 07:54:43.246088	1
5248	763	1	21.850	\N	2026-10-19 07:55:29.598512	1
5249	763	2	24.150	\N	2026-10-19 07:55:29.598512	1
5250	763	3	16.550	\N	2026-10-19 07:55:29.598512	1
5251	763	4	27.950	\N	2026-10-19 07:55:29.598512	1
5252	763	5	21.700	\N	2026-10-19 07:55:29.598512	1
5253	763	6	22.000	\N	2026-10-19 07:55:29.598512	1
5254	764	1	28.650	\N	2026-10-19 07:56:19.591738	1
5255	764	2	30.000	\N	2026-10-19 07:56:19.591738	1
5256	764	3	24.200	\N	2026-10-19 07:56:19.591738	1
5257	764	4	24.950	\N	2026-10-19 07:56:19.591738	1
5258	764	5	28.250	\N	2026-10-19 07:56:19.591738	1
5259	764	6	27.450	\N	2026-10-19 07:56:19.591738	1
5260	764	7	22.300	\N	2026-10-19 07:56:19.591738	1
5261	764	8	28.200	\N	2026-10-19 07:56:19.591738	1
5262	765	1	17.950	\N	2026-10-19 07:57:22.736826	1
5263	765	2	28.900	\N	2026-10-19 07:57:22.736826	1
5264	765	3	24.150	\N	2026-10-19 07:57:22.736826	1
5265	765	4	26.450	\N	2026-10-19 07:57:22.736826	1
5266	765	5	21.150	\N	2026-10-19 07:57:22.736826	1
5267	765	6	24.600	\N	2026-10-19 07:57:22.736826	1
5268	765	7	28.250	\N	2026-10-19 07:57:22.736826	1
5269	765	8	25.400	\N	2026-10-19 07:57:22.736826	1
5270	766	1	25.250	\N	2026-10-19 07:58:09.400956	1
5271	766	2	30.850	\N	2026-10-19 07:58:09.400956	1
5272	766	3	29.600	\N	2026-10-19 07:58:09.400956	1
5273	766	4	29.650	\N	2026-10-19 07:58:09.400956	1
5274	766	5	28.300	\N	2026-10-19 07:58:09.400956	1
5275	766	6	31.100	\N	2026-10-19 07:58:09.400956	1
5276	766	7	29.300	\N	2026-10-19 07:58:09.400956	1
5277	766	8	29.500	\N	2026-10-19 07:58:09.400956	1
5278	767	1	18.000	\N	2026-10-19 07:58:54.919536	1
5279	767	2	30.400	\N	2026-10-19 07:58:54.919536	1
5280	767	3	30.350	\N	2026-10-19 07:58:54.919536	1
5281	767	4	29.300	\N	2026-10-19 07:58:54.919536	1
5282	767	5	31.050	\N	2026-10-19 07:58:54.919536	1
5283	767	6	29.800	\N	2026-10-19 07:58:54.919536	1
5284	767	7	29.950	\N	2026-10-19 07:58:54.919536	1
5285	767	8	30.250	\N	2026-10-19 07:58:54.919536	1
5286	767	9	19.900	\N	2026-10-19 07:58:54.919536	1
5287	768	1	27.600	\N	2026-10-19 08:00:39.863706	1
5288	768	2	27.500	\N	2026-10-19 08:00:39.863706	1
5289	768	3	26.450	\N	2026-10-19 08:00:39.863706	1
5290	768	4	27.950	\N	2026-10-19 08:00:39.863706	1
5291	768	5	17.500	\N	2026-10-19 08:00:39.863706	1
5292	768	6	27.350	\N	2026-10-19 08:00:39.863706	1
5293	768	7	16.850	\N	2026-10-19 08:00:39.863706	1
5294	768	8	28.850	\N	2026-10-19 08:00:39.863706	1
5295	768	9	27.550	\N	2026-10-19 08:00:39.863706	1
5296	768	10	27.850	\N	2026-10-19 08:00:39.863706	1
5297	769	1	20.650	\N	2026-10-19 08:01:42.023431	1
5298	769	2	23.550	\N	2026-10-19 08:01:42.023431	1
5299	769	3	23.150	\N	2026-10-19 08:01:42.023431	1
5300	769	4	24.500	\N	2026-10-19 08:01:42.023431	1
5301	770	1	17.550	\N	2026-10-19 08:02:40.03652	1
5302	770	2	27.250	\N	2026-10-19 08:02:40.03652	1
5303	770	3	24.000	\N	2026-10-19 08:02:40.03652	1
5304	770	4	24.100	\N	2026-10-19 08:02:40.03652	1
5305	770	5	21.900	\N	2026-10-19 08:02:40.03652	1
5306	770	6	21.250	\N	2026-10-19 08:02:40.03652	1
5307	770	7	27.000	\N	2026-10-19 08:02:40.03652	1
5308	771	1	29.450	\N	2026-10-19 08:03:35.832594	1
5309	771	2	19.450	\N	2026-10-19 08:03:35.832594	1
5310	771	3	28.100	\N	2026-10-19 08:03:35.832594	1
5311	771	4	29.300	\N	2026-10-19 08:03:35.832594	1
5312	771	5	28.800	\N	2026-10-19 08:03:35.832594	1
5313	771	6	33.050	\N	2026-10-19 08:03:35.832594	1
5314	771	7	17.850	\N	2026-10-19 08:03:35.832594	1
5315	772	1	30.350	\N	2026-10-19 08:04:35.610354	1
5316	772	2	26.050	\N	2026-10-19 08:04:35.610354	1
5317	772	3	29.100	\N	2026-10-19 08:04:35.610354	1
5318	772	4	29.300	\N	2026-10-19 08:04:35.610354	1
5319	772	5	29.150	\N	2026-10-19 08:04:35.610354	1
5320	772	6	28.900	\N	2026-10-19 08:04:35.610354	1
5321	772	7	28.050	\N	2026-10-19 08:04:35.610354	1
5322	772	8	29.450	\N	2026-10-19 08:04:35.610354	1
5323	773	1	21.950	\N	2026-10-20 06:36:56.631237	1
5324	773	2	24.800	\N	2026-10-20 06:36:56.631237	1
5325	773	3	16.050	\N	2026-10-20 06:36:56.631237	1
5326	773	4	23.550	\N	2026-10-20 06:36:56.631237	1
5327	773	5	25.100	\N	2026-10-20 06:36:56.631237	1
5328	773	6	24.150	\N	2026-10-20 06:36:56.631237	1
5329	773	7	25.950	\N	2026-10-20 06:36:56.631237	1
5330	773	8	26.000	\N	2026-10-20 06:36:56.631237	1
5331	774	1	29.450	\N	2026-10-20 06:38:08.930927	1
5332	774	2	29.750	\N	2026-10-20 06:38:08.930927	1
5333	774	3	20.700	\N	2026-10-20 06:38:08.930927	1
5334	774	4	30.300	\N	2026-10-20 06:38:08.930927	1
5335	774	5	27.850	\N	2026-10-20 06:38:08.930927	1
5336	774	6	29.300	\N	2026-10-20 06:38:08.930927	1
5337	774	7	28.900	\N	2026-10-20 06:38:08.930927	1
5338	774	8	29.100	\N	2026-10-20 06:38:08.930927	1
5339	775	1	26.900	\N	2026-10-20 06:38:57.726635	1
5340	775	2	29.050	\N	2026-10-20 06:38:57.726635	1
5341	775	3	27.800	\N	2026-10-20 06:38:57.726635	1
5342	775	4	23.450	\N	2026-10-20 06:38:57.726635	1
5343	775	5	27.350	\N	2026-10-20 06:38:57.726635	1
5344	775	6	22.450	\N	2026-10-20 06:38:57.726635	1
5345	775	7	27.600	\N	2026-10-20 06:38:57.726635	1
5346	775	8	31.000	\N	2026-10-20 06:38:57.726635	1
5347	775	9	33.900	\N	2026-10-20 06:38:57.726635	1
5348	776	1	25.900	\N	2026-10-20 06:40:07.792761	1
5349	776	2	20.350	\N	2026-10-20 06:40:07.792761	1
5350	776	3	25.450	\N	2026-10-20 06:40:07.792761	1
5351	776	4	20.300	\N	2026-10-20 06:40:07.792761	1
5352	776	5	24.150	\N	2026-10-20 06:40:07.792761	1
5353	776	6	24.150	\N	2026-10-20 06:40:07.792761	1
5354	776	7	22.400	\N	2026-10-20 06:40:07.792761	1
5355	776	8	26.650	\N	2026-10-20 06:40:07.792761	1
5356	776	9	17.650	\N	2026-10-20 06:40:07.792761	1
5357	776	10	10.900	\N	2026-10-20 06:40:07.792761	1
5358	777	1	20.950	\N	2026-10-20 06:41:00.131308	1
5359	777	2	22.500	\N	2026-10-20 06:41:00.131308	1
5360	777	3	24.150	\N	2026-10-20 06:41:00.131308	1
5361	777	4	19.250	\N	2026-10-20 06:41:00.131308	1
5362	778	1	21.500	\N	2026-10-20 06:41:53.520901	1
5363	778	2	20.650	\N	2026-10-20 06:41:53.520901	1
5364	778	3	17.300	\N	2026-10-20 06:41:53.520901	1
5365	778	4	23.250	\N	2026-10-20 06:41:53.520901	1
5366	778	5	25.300	\N	2026-10-20 06:41:53.520901	1
5367	778	6	23.850	\N	2026-10-20 06:41:53.520901	1
5368	778	7	12.400	\N	2026-10-20 06:41:53.520901	1
5369	779	1	25.800	\N	2026-10-20 06:42:41.712479	1
5370	779	2	21.350	\N	2026-10-20 06:42:41.712479	1
5371	779	3	27.350	\N	2026-10-20 06:42:41.712479	1
5372	779	4	26.950	\N	2026-10-20 06:42:41.712479	1
5373	779	5	29.800	\N	2026-10-20 06:42:41.712479	1
5374	779	6	24.650	\N	2026-10-20 06:42:41.712479	1
5375	779	7	22.550	\N	2026-10-20 06:42:41.712479	1
5376	780	1	25.450	\N	2026-10-20 06:43:32.37848	1
5377	780	2	26.600	\N	2026-10-20 06:43:32.37848	1
5378	780	3	20.450	\N	2026-10-20 06:43:32.37848	1
5379	780	4	25.450	\N	2026-10-20 06:43:32.37848	1
5380	780	5	28.800	\N	2026-10-20 06:43:32.37848	1
5381	780	6	28.900	\N	2026-10-20 06:43:32.37848	1
5382	780	7	30.750	\N	2026-10-20 06:43:32.37848	1
5383	780	8	28.850	\N	2026-10-20 06:43:32.37848	1
5384	781	1	23.850	\N	2026-10-20 06:44:27.206384	1
5385	781	2	21.300	\N	2026-10-20 06:44:27.206384	1
5386	781	3	22.750	\N	2026-10-20 06:44:27.206384	1
5387	781	4	24.800	\N	2026-10-20 06:44:27.206384	1
5388	781	5	24.700	\N	2026-10-20 06:44:27.206384	1
5389	781	6	23.500	\N	2026-10-20 06:44:27.206384	1
5390	781	7	23.050	\N	2026-10-20 06:44:27.206384	1
5391	781	8	26.950	\N	2026-10-20 06:44:27.206384	1
5392	782	1	20.500	\N	2026-10-20 06:45:13.629232	1
5393	782	2	23.550	\N	2026-10-20 06:45:13.629232	1
5394	782	3	30.700	\N	2026-10-20 06:45:13.629232	1
5395	782	4	30.900	\N	2026-10-20 06:45:13.629232	1
5396	782	5	30.850	\N	2026-10-20 06:45:13.629232	1
5397	782	6	30.200	\N	2026-10-20 06:45:13.629232	1
5398	782	7	30.500	\N	2026-10-20 06:45:13.629232	1
5399	782	8	30.600	\N	2026-10-20 06:45:13.629232	1
5400	783	1	30.900	\N	2026-10-20 06:45:56.638441	1
5401	783	2	19.800	\N	2026-10-20 06:45:56.638441	1
5402	783	3	24.300	\N	2026-10-20 06:45:56.638441	1
5403	783	4	30.950	\N	2026-10-20 06:45:56.638441	1
5404	783	5	30.850	\N	2026-10-20 06:45:56.638441	1
5405	783	6	30.950	\N	2026-10-20 06:45:56.638441	1
5406	783	7	31.000	\N	2026-10-20 06:45:56.638441	1
5407	783	8	30.300	\N	2026-10-20 06:45:56.638441	1
5408	784	1	16.250	\N	2026-10-20 06:47:01.109208	1
5409	784	2	27.450	\N	2026-10-20 06:47:01.109208	1
5410	784	3	28.550	\N	2026-10-20 06:47:01.109208	1
5411	784	4	28.800	\N	2026-10-20 06:47:01.109208	1
5412	784	5	29.800	\N	2026-10-20 06:47:01.109208	1
5413	784	6	28.700	\N	2026-10-20 06:47:01.109208	1
5414	784	7	16.250	\N	2026-10-20 06:47:01.109208	1
5415	784	8	27.700	\N	2026-10-20 06:47:01.109208	1
5416	784	9	27.100	\N	2026-10-20 06:47:01.109208	1
5417	784	10	28.200	\N	2026-10-20 06:47:01.109208	1
5418	785	1	22.550	\N	2026-10-20 06:47:37.227194	1
5419	785	2	23.950	\N	2026-10-20 06:47:37.227194	1
5420	785	3	19.250	\N	2026-10-20 06:47:37.227194	1
5421	785	4	22.300	\N	2026-10-20 06:47:37.227194	1
5422	786	1	17.300	\N	2026-10-20 06:48:30.227564	1
5423	786	2	24.500	\N	2026-10-20 06:48:30.227564	1
5424	786	3	25.350	\N	2026-10-20 06:48:30.227564	1
5425	786	4	23.450	\N	2026-10-20 06:48:30.227564	1
5426	786	5	17.000	\N	2026-10-20 06:48:30.227564	1
5427	786	6	27.900	\N	2026-10-20 06:48:30.227564	1
5428	786	7	24.050	\N	2026-10-20 06:48:30.227564	1
5429	786	8	15.500	\N	2026-10-20 06:48:30.227564	1
5430	787	1	28.250	\N	2026-10-20 06:49:21.649195	1
5431	787	2	21.650	\N	2026-10-20 06:49:21.649195	1
5432	787	3	22.750	\N	2026-10-20 06:49:21.649195	1
5433	787	4	28.750	\N	2026-10-20 06:49:21.649195	1
5434	787	5	28.950	\N	2026-10-20 06:49:21.649195	1
5435	787	6	30.650	\N	2026-10-20 06:49:21.649195	1
5436	787	7	29.400	\N	2026-10-20 06:49:21.649195	1
5437	787	8	32.400	\N	2026-10-20 06:49:21.649195	1
5438	788	1	30.200	\N	2026-10-20 06:50:07.018041	1
5439	788	2	29.400	\N	2026-10-20 06:50:07.018041	1
5440	788	3	29.250	\N	2026-10-20 06:50:07.018041	1
5441	788	4	29.200	\N	2026-10-20 06:50:07.018041	1
5442	788	5	29.250	\N	2026-10-20 06:50:07.018041	1
5443	788	6	29.000	\N	2026-10-20 06:50:07.018041	1
5444	788	7	31.000	\N	2026-10-20 06:50:07.018041	1
5445	788	8	28.250	\N	2026-10-20 06:50:07.018041	1
5446	789	1	24.050	\N	2026-10-21 06:42:10.935721	1
5447	789	2	29.500	\N	2026-10-21 06:42:10.935721	1
5448	789	3	29.750	\N	2026-10-21 06:42:10.935721	1
5449	789	4	23.300	\N	2026-10-21 06:42:10.935721	1
5450	789	5	19.200	\N	2026-10-21 06:42:10.935721	1
5451	789	6	28.550	\N	2026-10-21 06:42:10.935721	1
5452	789	7	24.800	\N	2026-10-21 06:42:10.935721	1
5453	790	1	29.100	\N	2026-10-21 06:47:46.008247	1
5454	790	2	22.150	\N	2026-10-21 06:47:46.008247	1
5455	790	3	22.950	\N	2026-10-21 06:47:46.008247	1
5456	790	4	25.450	\N	2026-10-21 06:47:46.008247	1
5457	790	5	30.700	\N	2026-10-21 06:47:46.008247	1
5458	790	6	25.850	\N	2026-10-21 06:47:46.008247	1
5459	790	7	28.500	\N	2026-10-21 06:47:46.008247	1
5460	790	8	27.950	\N	2026-10-21 06:47:46.008247	1
5461	791	1	29.550	\N	2026-10-21 06:48:40.54885	1
5462	791	2	31.550	\N	2026-10-21 06:48:40.54885	1
5463	791	3	28.300	\N	2026-10-21 06:48:40.54885	1
5464	791	4	25.550	\N	2026-10-21 06:48:40.54885	1
5465	791	5	29.450	\N	2026-10-21 06:48:40.54885	1
5466	791	6	27.300	\N	2026-10-21 06:48:40.54885	1
5467	791	7	28.450	\N	2026-10-21 06:48:40.54885	1
5468	791	8	26.750	\N	2026-10-21 06:48:40.54885	1
5469	792	1	24.050	\N	2026-10-21 06:49:16.15872	1
5470	792	2	25.300	\N	2026-10-21 06:49:16.15872	1
5471	793	1	25.450	\N	2026-10-21 06:50:17.31348	1
5472	793	2	30.800	\N	2026-10-21 06:50:17.31348	1
5473	793	3	27.400	\N	2026-10-21 06:50:17.31348	1
5474	793	4	28.050	\N	2026-10-21 06:50:17.31348	1
5475	793	5	20.650	\N	2026-10-21 06:50:17.31348	1
5476	793	6	29.450	\N	2026-10-21 06:50:17.31348	1
5477	793	7	20.650	\N	2026-10-21 06:50:17.31348	1
5478	794	1	21.200	\N	2026-10-21 06:50:45.290465	1
5479	794	2	24.600	\N	2026-10-21 06:50:45.290465	1
5480	794	3	20.200	\N	2026-10-21 06:50:45.290465	1
5481	795	1	20.900	\N	2026-10-21 06:51:31.889154	1
5482	795	2	19.400	\N	2026-10-21 06:51:31.889154	1
5483	795	3	21.800	\N	2026-10-21 06:51:31.889154	1
5484	795	4	22.400	\N	2026-10-21 06:51:31.889154	1
5485	795	5	19.000	\N	2026-10-21 06:51:31.889154	1
5486	795	6	16.700	\N	2026-10-21 06:51:31.889154	1
5487	796	1	27.100	\N	2026-10-21 06:52:21.026869	1
5488	796	2	28.950	\N	2026-10-21 06:52:21.026869	1
5489	796	3	21.000	\N	2026-10-21 06:52:21.026869	1
5490	796	4	17.350	\N	2026-10-21 06:52:21.026869	1
5491	796	5	30.300	\N	2026-10-21 06:52:21.026869	1
5492	796	6	23.450	\N	2026-10-21 06:52:21.026869	1
5493	796	7	31.650	\N	2026-10-21 06:52:21.026869	1
5494	797	1	30.250	\N	2026-10-21 06:53:28.667317	1
5495	797	2	28.750	\N	2026-10-21 06:53:28.667317	1
5496	797	3	21.900	\N	2026-10-21 06:53:28.667317	1
5497	797	4	20.200	\N	2026-10-21 06:53:28.667317	1
5498	797	5	27.400	\N	2026-10-21 06:53:28.667317	1
5499	797	6	27.950	\N	2026-10-21 06:53:28.667317	1
5500	797	7	25.700	\N	2026-10-21 06:53:28.667317	1
5501	797	8	29.800	\N	2026-10-21 06:53:28.667317	1
5502	798	1	19.850	\N	2026-10-21 07:09:02.857655	1
5503	798	2	29.200	\N	2026-10-21 07:09:02.857655	1
5504	798	3	29.100	\N	2026-10-21 07:09:02.857655	1
5505	798	4	27.150	\N	2026-10-21 07:09:02.857655	1
5506	798	5	29.250	\N	2026-10-21 07:09:02.857655	1
5507	798	6	28.150	\N	2026-10-21 07:09:02.857655	1
5508	798	7	29.900	\N	2026-10-21 07:09:02.857655	1
5509	799	1	31.100	\N	2026-10-21 07:09:49.524483	1
5510	799	2	30.800	\N	2026-10-21 07:09:49.524483	1
5511	799	3	32.900	\N	2026-10-21 07:09:49.524483	1
5512	799	4	30.900	\N	2026-10-21 07:09:49.524483	1
5513	799	5	29.650	\N	2026-10-21 07:09:49.524483	1
5514	799	6	32.750	\N	2026-10-21 07:09:49.524483	1
5515	799	7	30.300	\N	2026-10-21 07:09:49.524483	1
5516	800	1	33.200	\N	2026-10-21 07:10:29.041463	1
5517	800	2	32.850	\N	2026-10-21 07:10:29.041463	1
5518	800	3	31.250	\N	2026-10-21 07:10:29.041463	1
5519	800	4	31.000	\N	2026-10-21 07:10:29.041463	1
5520	800	5	31.300	\N	2026-10-21 07:10:29.041463	1
5521	800	6	32.250	\N	2026-10-21 07:10:29.041463	1
5522	800	7	29.950	\N	2026-10-21 07:10:29.041463	1
5523	801	1	17.600	\N	2026-10-21 07:11:39.127832	1
5524	801	2	30.150	\N	2026-10-21 07:11:39.127832	1
5525	801	3	30.250	\N	2026-10-21 07:11:39.127832	1
5526	801	4	30.850	\N	2026-10-21 07:11:39.127832	1
5527	801	5	16.350	\N	2026-10-21 07:11:39.127832	1
5528	801	6	31.850	\N	2026-10-21 07:11:39.127832	1
5529	801	7	30.200	\N	2026-10-21 07:11:39.127832	1
5530	801	8	31.400	\N	2026-10-21 07:11:39.127832	1
5531	801	9	30.800	\N	2026-10-21 07:11:39.127832	1
5532	801	10	30.900	\N	2026-10-21 07:11:39.127832	1
5533	801	11	31.600	\N	2026-10-21 07:11:39.127832	1
5534	802	1	24.350	\N	2026-10-21 07:12:57.920538	1
5535	802	2	23.750	\N	2026-10-21 07:12:57.920538	1
5536	802	3	23.350	\N	2026-10-21 07:12:57.920538	1
5537	802	4	27.100	\N	2026-10-21 07:12:57.920538	1
5538	803	1	23.700	\N	2026-10-21 07:13:37.107629	1
5539	803	2	26.700	\N	2026-10-21 07:13:37.107629	1
5540	803	3	15.050	\N	2026-10-21 07:13:37.107629	1
5541	803	4	21.000	\N	2026-10-21 07:13:37.107629	1
5542	803	5	25.650	\N	2026-10-21 07:13:37.107629	1
5543	803	6	24.950	\N	2026-10-21 07:13:37.107629	1
5544	803	7	25.500	\N	2026-10-21 07:13:37.107629	1
5545	804	1	20.400	\N	2026-10-21 07:14:21.494138	1
5546	804	2	31.350	\N	2026-10-21 07:14:21.494138	1
5547	804	3	17.100	\N	2026-10-21 07:14:21.494138	1
5548	804	4	28.800	\N	2026-10-21 07:14:21.494138	1
5549	804	5	26.350	\N	2026-10-21 07:14:21.494138	1
5550	804	6	28.900	\N	2026-10-21 07:14:21.494138	1
5551	804	7	28.800	\N	2026-10-21 07:14:21.494138	1
5552	804	8	29.400	\N	2026-10-21 07:14:21.494138	1
5553	805	1	29.150	\N	2026-10-21 07:15:09.951038	1
5554	805	2	32.300	\N	2026-10-21 07:15:09.951038	1
5555	805	3	31.950	\N	2026-10-21 07:15:09.951038	1
5556	805	4	29.300	\N	2026-10-21 07:15:09.951038	1
5557	805	5	29.200	\N	2026-10-21 07:15:09.951038	1
5558	805	6	29.000	\N	2026-10-21 07:15:09.951038	1
5559	805	7	29.350	\N	2026-10-21 07:15:09.951038	1
5560	805	8	29.200	\N	2026-10-21 07:15:09.951038	1
5561	806	1	23.900	\N	2026-10-22 05:59:21.242842	1
5562	806	2	25.350	\N	2026-10-22 05:59:21.242842	1
5563	806	3	27.950	\N	2026-10-22 05:59:21.242842	1
5564	806	4	23.700	\N	2026-10-22 05:59:21.242842	1
5565	806	5	26.950	\N	2026-10-22 05:59:21.242842	1
5566	806	6	28.800	\N	2026-10-22 05:59:21.242842	1
5567	806	7	25.350	\N	2026-10-22 05:59:21.242842	1
5568	806	8	23.100	\N	2026-10-22 05:59:21.242842	1
5569	807	1	28.600	\N	2026-10-22 06:01:18.451075	1
5570	807	2	26.200	\N	2026-10-22 06:01:18.451075	1
5571	807	3	29.250	\N	2026-10-22 06:01:18.451075	1
5572	807	4	30.200	\N	2026-10-22 06:01:18.451075	1
5573	807	5	29.450	\N	2026-10-22 06:01:18.451075	1
5574	807	6	29.500	\N	2026-10-22 06:01:18.451075	1
5575	807	7	28.350	\N	2026-10-22 06:01:18.451075	1
5576	807	8	27.800	\N	2026-10-22 06:01:18.451075	1
5577	808	1	29.600	\N	2026-10-22 06:02:08.237759	1
5578	808	2	20.300	\N	2026-10-22 06:02:08.237759	1
5579	808	3	31.150	\N	2026-10-22 06:02:08.237759	1
5580	808	4	28.750	\N	2026-10-22 06:02:08.237759	1
5581	808	5	24.750	\N	2026-10-22 06:02:08.237759	1
5582	808	6	29.500	\N	2026-10-22 06:02:08.237759	1
5583	808	7	22.000	\N	2026-10-22 06:02:08.237759	1
5584	808	8	28.500	\N	2026-10-22 06:02:08.237759	1
5585	809	1	34.700	\N	2026-10-22 06:02:57.599006	1
5586	809	2	28.250	\N	2026-10-22 06:02:57.599006	1
5587	809	3	32.400	\N	2026-10-22 06:02:57.599006	1
5588	809	4	30.600	\N	2026-10-22 06:02:57.599006	1
5589	809	5	27.250	\N	2026-10-22 06:02:57.599006	1
5590	809	6	28.650	\N	2026-10-22 06:02:57.599006	1
5591	809	7	31.750	\N	2026-10-22 06:02:57.599006	1
5592	809	8	24.350	\N	2026-10-22 06:02:57.599006	1
5593	809	9	30.200	\N	2026-10-22 06:02:57.599006	1
5594	809	10	22.100	\N	2026-10-22 06:02:57.599006	1
5595	810	1	20.000	\N	2026-10-22 06:03:33.349234	1
5596	810	2	15.000	\N	2026-10-22 06:03:33.349234	1
5597	811	1	26.000	\N	2026-10-22 06:04:08.104707	1
5598	811	2	23.650	\N	2026-10-22 06:04:08.104707	1
5599	811	3	20.700	\N	2026-10-22 06:04:08.104707	1
5600	811	4	25.650	\N	2026-10-22 06:04:08.104707	1
5608	813	1	24.350	\N	2026-10-22 06:06:28.603177	1
5609	813	2	26.850	\N	2026-10-22 06:06:28.603177	1
5610	813	3	28.000	\N	2026-10-22 06:06:28.603177	1
5611	813	4	27.600	\N	2026-10-22 06:06:28.603177	1
5612	813	5	29.150	\N	2026-10-22 06:06:28.603177	1
5613	813	6	15.500	\N	2026-10-22 06:06:28.603177	1
5614	813	7	26.950	\N	2026-10-22 06:06:28.603177	1
5615	814	1	28.700	\N	2026-10-22 06:07:46.790994	1
5616	814	2	28.000	\N	2026-10-22 06:07:46.790994	1
5617	814	3	28.200	\N	2026-10-22 06:07:46.790994	1
5618	814	4	29.950	\N	2026-10-22 06:07:46.790994	1
5619	814	5	26.900	\N	2026-10-22 06:07:46.790994	1
5620	814	6	29.050	\N	2026-10-22 06:07:46.790994	1
5621	814	7	25.050	\N	2026-10-22 06:07:46.790994	1
5622	814	8	22.650	\N	2026-10-22 06:07:46.790994	1
5623	815	1	33.400	\N	2026-10-22 06:11:20.100906	1
5624	815	2	28.000	\N	2026-10-22 06:11:20.100906	1
5625	815	3	29.800	\N	2026-10-22 06:11:20.100906	1
5626	815	4	29.750	\N	2026-10-22 06:11:20.100906	1
5627	815	5	30.000	\N	2026-10-22 06:11:20.100906	1
5628	815	6	29.100	\N	2026-10-22 06:11:20.100906	1
5629	816	1	30.800	\N	2026-10-22 06:12:04.604554	1
5630	816	2	31.050	\N	2026-10-22 06:12:04.604554	1
5631	816	3	31.050	\N	2026-10-22 06:12:04.604554	1
5632	816	4	34.000	\N	2026-10-22 06:12:04.604554	1
5633	816	5	30.750	\N	2026-10-22 06:12:04.604554	1
5634	816	6	31.100	\N	2026-10-22 06:12:04.604554	1
5635	816	7	30.600	\N	2026-10-22 06:12:04.604554	1
5636	817	1	22.200	\N	2026-10-22 06:12:51.603427	1
5637	817	2	31.400	\N	2026-10-22 06:12:51.603427	1
5638	817	3	31.300	\N	2026-10-22 06:12:51.603427	1
5639	817	4	24.100	\N	2026-10-22 06:12:51.603427	1
5640	817	5	31.250	\N	2026-10-22 06:12:51.603427	1
5641	817	6	31.550	\N	2026-10-22 06:12:51.603427	1
5642	817	7	32.800	\N	2026-10-22 06:12:51.603427	1
5643	817	8	31.150	\N	2026-10-22 06:12:51.603427	1
5644	818	1	32.600	\N	2026-10-22 06:13:52.880528	1
5645	818	2	31.150	\N	2026-10-22 06:13:52.880528	1
5646	818	3	29.500	\N	2026-10-22 06:13:52.880528	1
5647	818	4	14.900	\N	2026-10-22 06:13:52.880528	1
5648	818	5	22.600	\N	2026-10-22 06:13:52.880528	1
5649	818	6	23.350	\N	2026-10-22 06:13:52.880528	1
5650	818	7	30.150	\N	2026-10-22 06:13:52.880528	1
5651	818	8	30.700	\N	2026-10-22 06:13:52.880528	1
5652	818	9	30.850	\N	2026-10-22 06:13:52.880528	1
5653	818	10	32.500	\N	2026-10-22 06:13:52.880528	1
5654	818	11	31.950	\N	2026-10-22 06:13:52.880528	1
5655	819	1	17.750	\N	2026-10-22 06:14:27.373338	1
5656	819	2	19.100	\N	2026-10-22 06:14:27.373338	1
5657	819	3	24.500	\N	2026-10-22 06:14:27.373338	1
5658	819	4	25.900	\N	2026-10-22 06:14:27.373338	1
5659	820	1	21.250	\N	2026-10-22 06:15:14.734475	1
5660	820	2	12.550	\N	2026-10-22 06:15:14.734475	1
5661	820	3	23.350	\N	2026-10-22 06:15:14.734475	1
5662	820	4	25.050	\N	2026-10-22 06:15:14.734475	1
5663	820	5	26.050	\N	2026-10-22 06:15:14.734475	1
5664	820	6	21.900	\N	2026-10-22 06:15:14.734475	1
5665	821	1	15.350	\N	2026-10-22 06:50:03.435113	1
5666	821	2	24.050	\N	2026-10-22 06:50:03.435113	1
5667	821	3	27.950	\N	2026-10-22 06:50:03.435113	1
5668	821	4	29.750	\N	2026-10-22 06:50:03.435113	1
5669	821	5	32.300	\N	2026-10-22 06:50:03.435113	1
5670	821	6	30.150	\N	2026-10-22 06:50:03.435113	1
5671	821	7	29.000	\N	2026-10-22 06:50:03.435113	1
5672	821	8	30.150	\N	2026-10-22 06:50:03.435113	1
5673	822	1	29.100	\N	2026-10-22 06:50:57.652307	1
5674	822	2	29.400	\N	2026-10-22 06:50:57.652307	1
5675	822	3	29.400	\N	2026-10-22 06:50:57.652307	1
5676	822	4	29.300	\N	2026-10-22 06:50:57.652307	1
5677	822	5	29.200	\N	2026-10-22 06:50:57.652307	1
5678	822	6	26.350	\N	2026-10-22 06:50:57.652307	1
5679	822	7	26.150	\N	2026-10-22 06:50:57.652307	1
5680	822	8	24.300	\N	2026-10-22 06:50:57.652307	1
5681	812	1	19.650	\N	2026-10-22 06:52:13.65194	1
5682	812	2	18.950	\N	2026-10-22 06:52:13.65194	1
5683	812	3	25.550	\N	2026-10-22 06:52:13.65194	1
5684	812	4	19.350	\N	2026-10-22 06:52:13.65194	1
5685	812	5	21.050	\N	2026-10-22 06:52:13.65194	1
5686	812	6	26.300	\N	2026-10-22 06:52:13.65194	1
5687	812	7	21.900	\N	2026-10-22 06:52:13.65194	1
5688	823	1	29.000	\N	2026-10-23 05:13:57.900075	1
5689	823	2	25.500	\N	2026-10-23 05:13:57.900075	1
5690	823	3	23.150	\N	2026-10-23 05:13:57.900075	1
5691	823	4	28.800	\N	2026-10-23 05:13:57.900075	1
5692	823	5	23.950	\N	2026-10-23 05:13:57.900075	1
5693	823	6	22.400	\N	2026-10-23 05:13:57.900075	1
5694	823	7	22.000	\N	2026-10-23 05:13:57.900075	1
5695	824	1	27.550	\N	2026-10-23 05:14:43.395423	1
5696	824	2	28.200	\N	2026-10-23 05:14:43.395423	1
5697	824	3	29.550	\N	2026-10-23 05:14:43.395423	1
5698	824	4	30.350	\N	2026-10-23 05:14:43.395423	1
5699	824	5	25.800	\N	2026-10-23 05:14:43.395423	1
5700	824	6	30.550	\N	2026-10-23 05:14:43.395423	1
5701	824	7	28.600	\N	2026-10-23 05:14:43.395423	1
5702	824	8	26.250	\N	2026-10-23 05:14:43.395423	1
5703	825	1	14.750	\N	2026-10-23 05:19:21.797719	1
5704	825	2	27.300	\N	2026-10-23 05:19:21.797719	1
5705	825	3	26.900	\N	2026-10-23 05:19:21.797719	1
5706	825	4	29.050	\N	2026-10-23 05:19:21.797719	1
5707	825	5	30.550	\N	2026-10-23 05:19:21.797719	1
5708	825	6	27.300	\N	2026-10-23 05:19:21.797719	1
5709	825	7	28.200	\N	2026-10-23 05:19:21.797719	1
5710	825	8	24.500	\N	2026-10-23 05:19:21.797719	1
5711	826	1	18.700	\N	2026-10-23 05:20:08.64999	1
5712	826	2	29.200	\N	2026-10-23 05:20:08.64999	1
5713	826	3	27.050	\N	2026-10-23 05:20:08.64999	1
5714	826	4	33.800	\N	2026-10-23 05:20:08.64999	1
5715	826	5	33.800	\N	2026-10-23 05:20:08.64999	1
5716	826	6	26.900	\N	2026-10-23 05:20:08.64999	1
5717	826	7	31.500	\N	2026-10-23 05:20:08.64999	1
5718	826	8	25.850	\N	2026-10-23 05:20:08.64999	1
5719	826	9	22.700	\N	2026-10-23 05:20:08.64999	1
5720	827	1	25.350	\N	2026-10-23 05:20:49.240057	1
5721	827	2	22.850	\N	2026-10-23 05:20:49.240057	1
5722	827	3	23.350	\N	2026-10-23 05:20:49.240057	1
5723	827	4	22.300	\N	2026-10-23 05:20:49.240057	1
5724	828	1	25.800	\N	2026-10-23 05:21:52.720967	1
5725	828	2	22.350	\N	2026-10-23 05:21:52.720967	1
5726	828	3	15.700	\N	2026-10-23 05:21:52.720967	1
5727	828	4	19.400	\N	2026-10-23 05:21:52.720967	1
5728	828	5	21.450	\N	2026-10-23 05:21:52.720967	1
5729	828	6	27.250	\N	2026-10-23 05:21:52.720967	1
5730	828	7	7.000	\N	2026-10-23 05:21:52.720967	1
5731	828	8	19.150	\N	2026-10-23 05:21:52.720967	1
5732	829	1	24.700	\N	2026-10-23 05:22:41.502924	1
5733	829	2	26.450	\N	2026-10-23 05:22:41.502924	1
5734	829	3	25.000	\N	2026-10-23 05:22:41.502924	1
5735	829	4	23.200	\N	2026-10-23 05:22:41.502924	1
5736	829	5	21.050	\N	2026-10-23 05:22:41.502924	1
5737	829	6	13.750	\N	2026-10-23 05:22:41.502924	1
5738	829	7	18.150	\N	2026-10-23 05:22:41.502924	1
5739	829	8	22.000	\N	2026-10-23 05:22:41.502924	1
5740	830	1	30.350	\N	2026-10-23 05:24:26.444659	1
5741	830	2	27.950	\N	2026-10-23 05:24:26.444659	1
5742	830	3	29.000	\N	2026-10-23 05:24:26.444659	1
5743	830	4	27.950	\N	2026-10-23 05:24:26.444659	1
5744	830	5	27.400	\N	2026-10-23 05:24:26.444659	1
5745	830	6	29.750	\N	2026-10-23 05:24:26.444659	1
5746	830	7	28.250	\N	2026-10-23 05:24:26.444659	1
5747	830	8	26.000	\N	2026-10-23 05:24:26.444659	1
5748	831	1	24.600	\N	2026-10-23 05:25:27.529661	1
5749	831	2	17.900	\N	2026-10-23 05:25:27.529661	1
5750	831	3	28.900	\N	2026-10-23 05:25:27.529661	1
5751	831	4	29.450	\N	2026-10-23 05:25:27.529661	1
5752	831	5	29.450	\N	2026-10-23 05:25:27.529661	1
5753	831	6	29.050	\N	2026-10-23 05:25:27.529661	1
5754	831	7	29.000	\N	2026-10-23 05:25:27.529661	1
5755	832	1	27.800	\N	2026-10-23 05:26:12.91398	1
5756	832	2	27.500	\N	2026-10-23 05:26:12.91398	1
5757	832	3	29.950	\N	2026-10-23 05:26:12.91398	1
5758	832	4	21.000	\N	2026-10-23 05:26:12.91398	1
5759	832	5	30.900	\N	2026-10-23 05:26:12.91398	1
5760	832	6	30.850	\N	2026-10-23 05:26:12.91398	1
5761	832	7	28.850	\N	2026-10-23 05:26:12.91398	1
5762	832	8	30.950	\N	2026-10-23 05:26:12.91398	1
5763	833	1	29.950	\N	2026-10-23 05:26:55.239029	1
5764	833	2	31.600	\N	2026-10-23 05:26:55.239029	1
5765	833	3	31.350	\N	2026-10-23 05:26:55.239029	1
5766	833	4	31.150	\N	2026-10-23 05:26:55.239029	1
5767	833	5	31.400	\N	2026-10-23 05:26:55.239029	1
5768	833	6	31.100	\N	2026-10-23 05:26:55.239029	1
5769	833	7	31.300	\N	2026-10-23 05:26:55.239029	1
5770	834	1	33.900	\N	2026-10-23 05:27:45.923977	1
5771	834	2	31.550	\N	2026-10-23 05:27:45.923977	1
5772	834	3	31.200	\N	2026-10-23 05:27:45.923977	1
5773	834	4	30.350	\N	2026-10-23 05:27:45.923977	1
5774	834	5	31.650	\N	2026-10-23 05:27:45.923977	1
5775	834	6	31.000	\N	2026-10-23 05:27:45.923977	1
5776	834	7	16.500	\N	2026-10-23 05:27:45.923977	1
5777	834	8	31.350	\N	2026-10-23 05:27:45.923977	1
5778	834	9	29.800	\N	2026-10-23 05:27:45.923977	1
5779	834	10	20.800	\N	2026-10-23 05:27:45.923977	1
5780	835	1	24.300	\N	2026-10-23 05:28:23.111827	1
5781	835	2	22.100	\N	2026-10-23 05:28:23.111827	1
5782	835	3	22.700	\N	2026-10-23 05:28:23.111827	1
5783	835	4	22.600	\N	2026-10-23 05:28:23.111827	1
5784	836	1	28.000	\N	2026-10-23 05:29:23.007889	1
5785	836	2	26.450	\N	2026-10-23 05:29:23.007889	1
5786	836	3	29.650	\N	2026-10-23 05:29:23.007889	1
5787	836	4	26.750	\N	2026-10-23 05:29:23.007889	1
5788	836	5	25.700	\N	2026-10-23 05:29:23.007889	1
5789	836	6	27.850	\N	2026-10-23 05:29:23.007889	1
5790	836	7	27.700	\N	2026-10-23 05:29:23.007889	1
5791	837	1	31.050	\N	2026-10-23 05:30:03.091611	1
5792	837	2	22.800	\N	2026-10-23 05:30:03.091611	1
5793	837	3	30.950	\N	2026-10-23 05:30:03.091611	1
5794	837	4	30.050	\N	2026-10-23 05:30:03.091611	1
5795	837	5	31.950	\N	2026-10-23 05:30:03.091611	1
5796	837	6	30.050	\N	2026-10-23 05:30:03.091611	1
5797	837	7	30.050	\N	2026-10-23 05:30:03.091611	1
5798	838	1	32.050	\N	2026-10-23 05:30:52.118481	1
5799	838	2	29.550	\N	2026-10-23 05:30:52.118481	1
5800	838	3	26.400	\N	2026-10-23 05:30:52.118481	1
5801	838	4	27.500	\N	2026-10-23 05:30:52.118481	1
5802	838	5	31.800	\N	2026-10-23 05:30:52.118481	1
5803	838	6	29.550	\N	2026-10-23 05:30:52.118481	1
5804	838	7	29.500	\N	2026-10-23 05:30:52.118481	1
5805	838	8	29.650	\N	2026-10-23 05:30:52.118481	1
5806	839	1	26.850	\N	2026-10-24 05:23:47.33671	1
5807	839	2	22.050	\N	2026-10-24 05:23:47.33671	1
5808	839	3	22.800	\N	2026-10-24 05:23:47.33671	1
5809	839	4	28.100	\N	2026-10-24 05:23:47.33671	1
5810	839	5	30.900	\N	2026-10-24 05:23:47.33671	1
5811	840	1	30.350	\N	2026-10-24 05:25:17.199556	1
5812	840	2	30.450	\N	2026-10-24 05:25:17.199556	1
5813	840	3	23.600	\N	2026-10-24 05:25:17.199556	1
5814	840	4	29.500	\N	2026-10-24 05:25:17.199556	1
5815	840	5	28.050	\N	2026-10-24 05:25:17.199556	1
5816	840	6	29.850	\N	2026-10-24 05:25:17.199556	1
5817	840	7	26.950	\N	2026-10-24 05:25:17.199556	1
5818	841	1	31.450	\N	2026-10-24 05:26:50.943821	1
5819	841	2	22.050	\N	2026-10-24 05:26:50.943821	1
5820	841	3	29.950	\N	2026-10-24 05:26:50.943821	1
5821	841	4	25.200	\N	2026-10-24 05:26:50.943821	1
5822	841	5	26.050	\N	2026-10-24 05:26:50.943821	1
5823	841	6	29.850	\N	2026-10-24 05:26:50.943821	1
5824	841	7	25.150	\N	2026-10-24 05:26:50.943821	1
5825	842	1	26.650	\N	2026-10-24 05:27:45.316984	1
5826	842	2	32.550	\N	2026-10-24 05:27:45.316984	1
5827	842	3	33.700	\N	2026-10-24 05:27:45.316984	1
5828	842	4	28.300	\N	2026-10-24 05:27:45.316984	1
5829	842	5	35.800	\N	2026-10-24 05:27:45.316984	1
5830	842	6	16.300	\N	2026-10-24 05:27:45.316984	1
5831	842	7	28.400	\N	2026-10-24 05:27:45.316984	1
5832	842	8	28.150	\N	2026-10-24 05:27:45.316984	1
5833	843	1	28.300	\N	2026-10-24 05:28:22.533848	1
5834	843	2	27.000	\N	2026-10-24 05:28:22.533848	1
5835	843	3	25.300	\N	2026-10-24 05:28:22.533848	1
5836	844	1	28.000	\N	2026-10-24 05:29:10.313631	1
5837	844	2	23.150	\N	2026-10-24 05:29:10.313631	1
5838	844	3	28.700	\N	2026-10-24 05:29:10.313631	1
5839	844	4	24.100	\N	2026-10-24 05:29:10.313631	1
5840	844	5	27.050	\N	2026-10-24 05:29:10.313631	1
5841	845	1	26.900	\N	2026-10-24 05:29:29.994961	1
5842	846	1	30.250	\N	2026-10-24 05:30:27.123554	1
5843	846	2	24.200	\N	2026-10-24 05:30:27.123554	1
5844	846	3	30.000	\N	2026-10-24 05:30:27.123554	1
5845	846	4	8.350	\N	2026-10-24 05:30:27.123554	1
5846	846	5	18.700	\N	2026-10-24 05:30:27.123554	1
5847	847	1	23.900	\N	2026-10-24 05:31:34.082804	1
5848	847	2	24.550	\N	2026-10-24 05:31:34.082804	1
5849	847	3	30.650	\N	2026-10-24 05:31:34.082804	1
5850	847	4	25.650	\N	2026-10-24 05:31:34.082804	1
5851	847	5	29.900	\N	2026-10-24 05:31:34.082804	1
5852	847	6	27.200	\N	2026-10-24 05:31:34.082804	1
5853	847	7	26.650	\N	2026-10-24 05:31:34.082804	1
5854	848	1	33.500	\N	2026-10-24 05:32:48.914992	1
5855	848	2	29.300	\N	2026-10-24 05:32:48.914992	1
5856	848	3	29.900	\N	2026-10-24 05:32:48.914992	1
5857	848	4	29.150	\N	2026-10-24 05:32:48.914992	1
5858	848	5	29.300	\N	2026-10-24 05:32:48.914992	1
5859	848	6	31.800	\N	2026-10-24 05:32:48.914992	1
5860	849	1	31.000	\N	2026-10-24 05:35:19.237122	1
5861	849	2	32.550	\N	2026-10-24 05:35:19.237122	1
5862	849	3	31.900	\N	2026-10-24 05:35:19.237122	1
5863	849	4	31.100	\N	2026-10-24 05:35:19.237122	1
5864	849	5	30.850	\N	2026-10-24 05:35:19.237122	1
5865	849	6	31.050	\N	2026-10-24 05:35:19.237122	1
5866	849	7	32.750	\N	2026-10-24 05:35:19.237122	1
5867	850	1	29.550	\N	2026-10-24 05:36:09.127804	1
5868	850	2	33.250	\N	2026-10-24 05:36:09.127804	1
5869	850	3	33.000	\N	2026-10-24 05:36:09.127804	1
5870	850	4	31.450	\N	2026-10-24 05:36:09.127804	1
5871	850	5	31.450	\N	2026-10-24 05:36:09.127804	1
5872	850	6	32.550	\N	2026-10-24 05:36:09.127804	1
5873	850	7	31.400	\N	2026-10-24 05:36:09.127804	1
5874	851	1	35.250	\N	2026-10-24 05:36:38.3676	1
5875	851	2	31.150	\N	2026-10-24 05:36:38.3676	1
5876	851	3	29.950	\N	2026-10-24 05:36:38.3676	1
5881	853	1	30.650	\N	2026-10-24 05:38:20.824454	1
5882	853	2	22.000	\N	2026-10-24 05:38:20.824454	1
5883	853	3	29.400	\N	2026-10-24 05:38:20.824454	1
5884	853	4	29.100	\N	2026-10-24 05:38:20.824454	1
5885	853	5	29.600	\N	2026-10-24 05:38:20.824454	1
5886	853	6	27.300	\N	2026-10-24 05:38:20.824454	1
5887	853	7	21.600	\N	2026-10-24 05:38:20.824454	1
5888	854	1	29.450	\N	2026-10-24 05:39:11.430399	1
5889	854	2	29.650	\N	2026-10-24 05:39:11.430399	1
5890	854	3	31.100	\N	2026-10-24 05:39:11.430399	1
5891	854	4	29.650	\N	2026-10-24 05:39:11.430399	1
5892	854	5	29.800	\N	2026-10-24 05:39:11.430399	1
5893	854	6	29.800	\N	2026-10-24 05:39:11.430399	1
5894	854	7	29.250	\N	2026-10-24 05:39:11.430399	1
5895	854	8	30.000	\N	2026-10-24 05:39:11.430399	1
5896	852	1	21.650	\N	2026-10-24 05:40:21.209995	1
5897	852	2	20.750	\N	2026-10-24 05:40:21.209995	1
5898	852	3	26.450	\N	2026-10-24 05:40:21.209995	1
5899	852	4	24.700	\N	2026-10-24 05:40:21.209995	1
5900	855	1	17.050	\N	2026-10-25 05:42:39.757286	1
5901	856	1	24.700	\N	2026-10-25 05:42:56.556099	1
5902	857	1	28.100	\N	2026-10-25 05:43:45.818578	1
5903	857	2	30.350	\N	2026-10-25 05:43:45.818578	1
5904	857	3	29.200	\N	2026-10-25 05:43:45.818578	1
5905	857	4	30.900	\N	2026-10-25 05:43:45.818578	1
5906	857	5	24.400	\N	2026-10-25 05:43:45.818578	1
5907	857	6	28.350	\N	2026-10-25 05:43:45.818578	1
5908	857	7	29.200	\N	2026-10-25 05:43:45.818578	1
5909	858	1	37.350	\N	2026-10-25 05:44:34.469265	1
5910	858	2	29.500	\N	2026-10-25 05:44:34.469265	1
5911	858	3	31.850	\N	2026-10-25 05:44:34.469265	1
5912	858	4	24.850	\N	2026-10-25 05:44:34.469265	1
5913	858	5	29.700	\N	2026-10-25 05:44:34.469265	1
5914	858	6	29.150	\N	2026-10-25 05:44:34.469265	1
5915	858	7	31.550	\N	2026-10-25 05:44:34.469265	1
5916	859	1	33.450	\N	2026-10-25 05:45:10.552011	1
5917	859	2	28.900	\N	2026-10-25 05:45:10.552011	1
5918	859	3	25.000	\N	2026-10-25 05:45:10.552011	1
5919	859	4	20.650	\N	2026-10-25 05:45:10.552011	1
5920	860	1	17.200	\N	2026-10-25 05:45:48.786009	1
5921	860	2	28.150	\N	2026-10-25 05:45:48.786009	1
5922	860	3	21.450	\N	2026-10-25 05:45:48.786009	1
5923	860	4	26.250	\N	2026-10-25 05:45:48.786009	1
5924	861	1	14.750	\N	2026-10-25 05:46:20.422442	1
5925	861	2	17.700	\N	2026-10-25 05:46:20.422442	1
5926	861	3	28.700	\N	2026-10-25 05:46:20.422442	1
5927	862	1	19.400	\N	2026-10-25 05:47:12.352095	1
5928	862	2	16.650	\N	2026-10-25 05:47:12.352095	1
5929	862	3	15.950	\N	2026-10-25 05:47:12.352095	1
5930	862	4	22.250	\N	2026-10-25 05:47:12.352095	1
5931	862	5	27.050	\N	2026-10-25 05:47:12.352095	1
5932	862	6	22.750	\N	2026-10-25 05:47:12.352095	1
5933	862	7	28.150	\N	2026-10-25 05:47:12.352095	1
5934	863	1	17.600	\N	2026-10-25 05:48:02.893971	1
5935	863	2	31.450	\N	2026-10-25 05:48:02.893971	1
5936	863	3	30.400	\N	2026-10-25 05:48:02.893971	1
5937	863	4	29.500	\N	2026-10-25 05:48:02.893971	1
5938	863	5	30.000	\N	2026-10-25 05:48:02.893971	1
5939	863	6	29.100	\N	2026-10-25 05:48:02.893971	1
5940	863	7	29.300	\N	2026-10-25 05:48:02.893971	1
5941	864	1	29.650	\N	2026-10-25 05:48:58.163769	1
5942	864	2	30.750	\N	2026-10-25 05:48:58.163769	1
5943	864	3	29.550	\N	2026-10-25 05:48:58.163769	1
5944	864	4	28.100	\N	2026-10-25 05:48:58.163769	1
5945	864	5	29.750	\N	2026-10-25 05:48:58.163769	1
5946	864	6	31.000	\N	2026-10-25 05:48:58.163769	1
5947	864	7	31.900	\N	2026-10-25 05:48:58.163769	1
5948	865	1	21.300	\N	2026-10-25 05:49:46.056482	1
5949	865	2	23.600	\N	2026-10-25 05:49:46.056482	1
5950	865	3	28.450	\N	2026-10-25 05:49:46.056482	1
5951	865	4	30.800	\N	2026-10-25 05:49:46.056482	1
5952	865	5	29.300	\N	2026-10-25 05:49:46.056482	1
5953	865	6	29.850	\N	2026-10-25 05:49:46.056482	1
5954	865	7	32.000	\N	2026-10-25 05:49:46.056482	1
5955	865	8	30.800	\N	2026-10-25 05:49:46.056482	1
5956	866	1	25.150	\N	2026-10-25 05:50:30.65374	1
5957	866	2	24.900	\N	2026-10-25 05:50:30.65374	1
5958	866	3	29.950	\N	2026-10-25 05:50:30.65374	1
5959	866	4	30.050	\N	2026-10-25 05:50:30.65374	1
5960	866	5	29.750	\N	2026-10-25 05:50:30.65374	1
5961	866	6	30.850	\N	2026-10-25 05:50:30.65374	1
5962	866	7	31.250	\N	2026-10-25 05:50:30.65374	1
5963	866	8	31.450	\N	2026-10-25 05:50:30.65374	1
5964	867	1	29.550	\N	2026-10-25 05:51:36.544454	1
5965	867	2	29.850	\N	2026-10-25 05:51:36.544454	1
5966	867	3	21.300	\N	2026-10-25 05:51:36.544454	1
5967	867	4	31.600	\N	2026-10-25 05:51:36.544454	1
5968	867	5	30.800	\N	2026-10-25 05:51:36.544454	1
5969	867	6	30.600	\N	2026-10-25 05:51:36.544454	1
5970	867	7	29.700	\N	2026-10-25 05:51:36.544454	1
5971	867	8	29.850	\N	2026-10-25 05:51:36.544454	1
5972	867	9	30.000	\N	2026-10-25 05:51:36.544454	1
5973	868	1	26.850	\N	2026-10-25 05:52:18.834078	1
5974	868	2	23.900	\N	2026-10-25 05:52:18.834078	1
5975	868	3	23.800	\N	2026-10-25 05:52:18.834078	1
5976	868	4	24.300	\N	2026-10-25 05:52:18.834078	1
5977	869	1	17.700	\N	2026-10-25 05:53:12.963914	1
5978	869	2	27.400	\N	2026-10-25 05:53:12.963914	1
5979	869	3	26.100	\N	2026-10-25 05:53:12.963914	1
5980	869	4	25.350	\N	2026-10-25 05:53:12.963914	1
5981	869	5	29.850	\N	2026-10-25 05:53:12.963914	1
5982	869	6	22.000	\N	2026-10-25 05:53:12.963914	1
5983	869	7	25.350	\N	2026-10-25 05:53:12.963914	1
5984	869	8	27.350	\N	2026-10-25 05:53:12.963914	1
5985	870	1	15.500	\N	2026-10-25 05:54:45.480981	1
5986	870	2	29.200	\N	2026-10-25 05:54:45.480981	1
5987	870	3	28.050	\N	2026-10-25 05:54:45.480981	1
5988	870	4	18.750	\N	2026-10-25 05:54:45.480981	1
5989	870	5	30.300	\N	2026-10-25 05:54:45.480981	1
5990	870	6	30.800	\N	2026-10-25 05:54:45.480981	1
5991	870	7	30.550	\N	2026-10-25 05:54:45.480981	1
5992	870	8	32.100	\N	2026-10-25 05:54:45.480981	1
5993	871	1	29.700	\N	2026-10-25 05:55:36.27549	1
5994	871	2	29.600	\N	2026-10-25 05:55:36.27549	1
5995	871	3	29.750	\N	2026-10-25 05:55:36.27549	1
5996	871	4	25.250	\N	2026-10-25 05:55:36.27549	1
5997	871	5	29.650	\N	2026-10-25 05:55:36.27549	1
5998	871	6	29.550	\N	2026-10-25 05:55:36.27549	1
5999	871	7	30.250	\N	2026-10-25 05:55:36.27549	1
6000	871	8	33.750	\N	2026-10-25 05:55:36.27549	1
6001	872	1	30.900	\N	2026-10-26 09:00:32.497087	1
6002	872	2	29.200	\N	2026-10-26 09:00:32.497087	1
6003	872	3	27.150	\N	2026-10-26 09:00:32.497087	1
6004	872	4	27.250	\N	2026-10-26 09:00:32.497087	1
6005	872	5	30.450	\N	2026-10-26 09:00:32.497087	1
6006	872	6	31.450	\N	2026-10-26 09:00:32.497087	1
6007	872	7	30.100	\N	2026-10-26 09:00:32.497087	1
6008	873	1	28.050	\N	2026-10-26 09:02:11.814229	1
6009	873	2	27.500	\N	2026-10-26 09:02:11.814229	1
6010	873	3	25.150	\N	2026-10-26 09:02:11.814229	1
6011	873	4	29.550	\N	2026-10-26 09:02:11.814229	1
6012	873	5	29.250	\N	2026-10-26 09:02:11.814229	1
6013	873	6	28.950	\N	2026-10-26 09:02:11.814229	1
6014	873	7	28.750	\N	2026-10-26 09:02:11.814229	1
6015	873	8	28.550	\N	2026-10-26 09:02:11.814229	1
6016	874	1	17.550	\N	2026-10-26 09:02:59.208544	1
6017	874	2	29.550	\N	2026-10-26 09:02:59.208544	1
6018	874	3	28.700	\N	2026-10-26 09:02:59.208544	1
6019	874	4	23.600	\N	2026-10-26 09:02:59.208544	1
6020	874	5	30.000	\N	2026-10-26 09:02:59.208544	1
6021	874	6	27.150	\N	2026-10-26 09:02:59.208544	1
6022	874	7	29.500	\N	2026-10-26 09:02:59.208544	1
6023	875	1	29.000	\N	2026-10-26 09:03:43.732577	1
6024	875	2	29.800	\N	2026-10-26 09:03:43.732577	1
6025	875	3	28.900	\N	2026-10-26 09:03:43.732577	1
6026	875	4	28.650	\N	2026-10-26 09:03:43.732577	1
6027	875	5	30.350	\N	2026-10-26 09:03:43.732577	1
6028	875	6	27.550	\N	2026-10-26 09:03:43.732577	1
6029	875	7	32.450	\N	2026-10-26 09:03:43.732577	1
6030	875	8	28.150	\N	2026-10-26 09:03:43.732577	1
6031	876	1	27.600	\N	2026-10-26 09:04:16.41762	1
6032	876	2	21.950	\N	2026-10-26 09:04:16.41762	1
6033	876	3	21.800	\N	2026-10-26 09:04:16.41762	1
6034	877	1	22.800	\N	2026-10-26 09:05:01.746384	1
6035	877	2	14.400	\N	2026-10-26 09:05:01.746384	1
6036	877	3	22.000	\N	2026-10-26 09:05:01.746384	1
6037	877	4	21.800	\N	2026-10-26 09:05:01.746384	1
6038	877	5	27.000	\N	2026-10-26 09:05:01.746384	1
6039	877	6	22.300	\N	2026-10-26 09:05:01.746384	1
6040	877	7	18.400	\N	2026-10-26 09:05:01.746384	1
6041	877	8	21.000	\N	2026-10-26 09:05:01.746384	1
6042	878	1	36.800	\N	2026-10-26 09:05:46.998678	1
6043	878	2	19.900	\N	2026-10-26 09:05:46.998678	1
6044	878	3	26.350	\N	2026-10-26 09:05:46.998678	1
6045	878	4	28.150	\N	2026-10-26 09:05:46.998678	1
6046	878	5	29.700	\N	2026-10-26 09:05:46.998678	1
6047	878	6	33.250	\N	2026-10-26 09:05:46.998678	1
6048	878	7	23.500	\N	2026-10-26 09:05:46.998678	1
6049	879	1	29.250	\N	2026-10-26 09:06:37.31507	1
6050	879	2	30.000	\N	2026-10-26 09:06:37.31507	1
6051	879	3	24.600	\N	2026-10-26 09:06:37.31507	1
6052	879	4	26.750	\N	2026-10-26 09:06:37.31507	1
6053	879	5	27.800	\N	2026-10-26 09:06:37.31507	1
6054	879	6	26.100	\N	2026-10-26 09:06:37.31507	1
6055	879	7	29.000	\N	2026-10-26 09:06:37.31507	1
6056	879	8	28.900	\N	2026-10-26 09:06:37.31507	1
6057	880	1	31.350	\N	2026-10-26 09:07:32.634609	1
6058	880	2	30.950	\N	2026-10-26 09:07:32.634609	1
6059	880	3	29.300	\N	2026-10-26 09:07:32.634609	1
6060	880	4	29.400	\N	2026-10-26 09:07:32.634609	1
6061	880	5	28.100	\N	2026-10-26 09:07:32.634609	1
6062	880	6	23.650	\N	2026-10-26 09:07:32.634609	1
6063	880	7	25.200	\N	2026-10-26 09:07:32.634609	1
6064	880	8	29.600	\N	2026-10-26 09:07:32.634609	1
6065	881	1	33.200	\N	2026-10-26 09:08:30.109633	1
6066	881	2	29.350	\N	2026-10-26 09:08:30.109633	1
6067	881	3	28.300	\N	2026-10-26 09:08:30.109633	1
6068	881	4	30.550	\N	2026-10-26 09:08:30.109633	1
6069	881	5	29.300	\N	2026-10-26 09:08:30.109633	1
6070	881	6	30.200	\N	2026-10-26 09:08:30.109633	1
6071	881	7	29.650	\N	2026-10-26 09:08:30.109633	1
6072	881	8	24.750	\N	2026-10-26 09:08:30.109633	1
6073	882	1	23.000	\N	2026-10-26 09:09:16.318458	1
6074	882	2	30.850	\N	2026-10-26 09:09:16.318458	1
6075	882	3	31.250	\N	2026-10-26 09:09:16.318458	1
6076	882	4	29.900	\N	2026-10-26 09:09:16.318458	1
6077	882	5	31.200	\N	2026-10-26 09:09:16.318458	1
6078	882	6	31.150	\N	2026-10-26 09:09:16.318458	1
6079	882	7	31.750	\N	2026-10-26 09:09:16.318458	1
6080	882	8	31.400	\N	2026-10-26 09:09:16.318458	1
6081	883	1	30.250	\N	2026-10-26 09:10:13.196488	1
6082	883	2	29.800	\N	2026-10-26 09:10:13.196488	1
6083	883	3	32.350	\N	2026-10-26 09:10:13.196488	1
6084	883	4	30.850	\N	2026-10-26 09:10:13.196488	1
6085	883	5	30.450	\N	2026-10-26 09:10:13.196488	1
6086	883	6	25.700	\N	2026-10-26 09:10:13.196488	1
6087	883	7	22.300	\N	2026-10-26 09:10:13.196488	1
6088	883	8	29.850	\N	2026-10-26 09:10:13.196488	1
6089	883	9	29.600	\N	2026-10-26 09:10:13.196488	1
6090	884	1	12.950	\N	2026-10-26 09:10:42.317508	1
6091	885	1	18.750	\N	2026-10-26 09:12:02.69052	1
6092	885	2	22.350	\N	2026-10-26 09:12:02.69052	1
6093	885	3	26.650	\N	2026-10-26 09:12:02.69052	1
6094	885	4	24.750	\N	2026-10-26 09:12:02.69052	1
6095	885	5	26.750	\N	2026-10-26 09:12:02.69052	1
6096	885	6	27.050	\N	2026-10-26 09:12:02.69052	1
6097	885	7	29.850	\N	2026-10-26 09:12:02.69052	1
6098	885	8	28.550	\N	2026-10-26 09:12:02.69052	1
6099	886	1	34.200	\N	2026-10-26 09:12:43.016781	1
6100	886	2	28.500	\N	2026-10-26 09:12:43.016781	1
6101	886	3	30.500	\N	2026-10-26 09:12:43.016781	1
6102	886	4	31.100	\N	2026-10-26 09:12:43.016781	1
6103	886	5	30.800	\N	2026-10-26 09:12:43.016781	1
6104	886	6	28.300	\N	2026-10-26 09:12:43.016781	1
6105	887	1	29.350	\N	2026-10-26 09:13:30.908987	1
6106	887	2	29.600	\N	2026-10-26 09:13:30.908987	1
6107	887	3	29.650	\N	2026-10-26 09:13:30.908987	1
6108	887	4	29.700	\N	2026-10-26 09:13:30.908987	1
6109	887	5	27.400	\N	2026-10-26 09:13:30.908987	1
6110	887	6	29.000	\N	2026-10-26 09:13:30.908987	1
6111	887	7	31.650	\N	2026-10-26 09:13:30.908987	1
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
502	2026-09-25	21	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-26 05:29:01.645652	\N	2026-09-26 05:29:01.645652	t	404	2026-09-26 08:07:28.385	1
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
687	2026-10-13	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-14 06:09:03.3994	\N	2026-10-14 06:09:03.3994	t	459	2026-10-14 09:43:12.886	1
721	2026-10-15	14	46	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-16 06:14:21.507637	\N	2026-10-16 06:14:21.507637	t	476	2026-10-16 06:47:18.516	1
210	2026-08-19	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-20 04:35:30.244206	\N	2026-08-20 04:35:30.244206	t	236	2026-08-20 08:25:26.459	1
214	2026-08-19	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-20 04:38:54.492376	\N	2026-08-20 04:38:54.492376	t	237	2026-08-20 08:27:05.869	1
206	2026-08-19	15	8	17	Morning	submitted	\N	Iftikhar Ahmed	2026-08-20 04:25:32.833822	\N	2026-08-20 04:25:32.833822	t	238	2026-08-20 08:30:31.123	1
148	2026-08-12	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-13 04:43:22.223796	\N	2026-08-13 04:43:22.223796	t	208	2026-08-13 08:11:22.65	1
149	2026-08-12	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-13 04:44:35.224753	\N	2026-08-13 04:44:35.224753	t	208	2026-08-13 08:11:22.65	1
150	2026-08-12	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-13 04:45:34.228718	\N	2026-08-13 04:45:34.228718	t	208	2026-08-13 08:11:22.65	1
153	2026-08-12	25	9	14	Night	submitted	\N	Iftikhar	2026-08-13 04:48:05.77479	\N	2026-08-13 04:48:05.77479	t	208	2026-08-13 08:11:22.65	1
154	2026-08-12	14	9	14	Night	submitted	\N	Iftikhar	2026-08-13 04:49:14.216822	\N	2026-08-13 04:49:14.216822	t	208	2026-08-13 08:11:22.65	1
155	2026-08-12	15	2	14	Night	submitted	\N	Iftikhar	2026-08-13 04:50:17.260845	\N	2026-08-13 04:50:17.260845	t	208	2026-08-13 08:11:22.65	1
722	2026-10-15	15	46	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-16 06:15:01.525946	\N	2026-10-16 06:15:01.525946	t	476	2026-10-16 06:47:18.516	1
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
360	2026-09-09	18	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-10 05:04:56.107017	\N	2026-09-10 05:04:56.107017	t	346	2026-09-10 09:51:02.662	1
676	2026-10-12	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-13 05:53:30.385221	\N	2026-10-13 05:53:30.385221	t	452	2026-10-13 06:54:31.515	1
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
262	2026-08-29	25	1	15	Morning	submitted	\N	Iftikhar Ahmed	2026-08-30 06:29:46.255071	\N	2026-08-30 06:29:46.255071	t	292	2026-08-31 09:11:42.395	1
263	2026-08-29	14	8	15	Morning	submitted	\N	Iftikhar Ahmed	2026-08-30 06:31:19.933643	\N	2026-08-30 06:31:19.933643	t	292	2026-08-31 09:11:42.395	1
266	2026-08-29	25	9	15	Night	submitted	\N	Iftikhar Ahmed	2026-08-30 06:35:27.52574	\N	2026-08-30 06:35:27.52574	t	292	2026-08-31 09:11:42.395	1
270	2026-08-30	23	7	13	Morning	submitted	\N	Iftikhar Ahmed	2026-08-31 06:05:03.286897	\N	2026-08-31 06:05:03.286897	t	293	2026-08-31 09:14:33.307	1
271	2026-08-30	24	1	13	Morning	submitted	\N	Iftikhar Ahmed	2026-08-31 06:05:46.504167	\N	2026-08-31 06:05:46.504167	t	293	2026-08-31 09:14:33.307	1
362	2026-09-09	15	7	23	Morning	submitted	\N	Iftikhar Ahmed	2026-09-10 05:47:10.915818	\N	2026-09-10 05:47:10.915818	t	347	2026-09-10 09:53:51.16	1
264	2026-08-29	23	7	13	Morning	submitted	\N	Iftikhar Ahmed	2026-08-30 06:33:10.395894	\N	2026-08-30 06:33:10.395894	t	291	2026-08-31 09:08:50.323	1
265	2026-08-29	24	1	13	Morning	submitted	\N	Iftikhar Ahmed	2026-08-30 06:34:09.320377	\N	2026-08-30 06:34:09.320377	t	291	2026-08-31 09:08:50.323	1
268	2026-08-29	23	2	13	Night	submitted	\N	Iftikhar Ahmed	2026-08-30 06:37:46.079886	\N	2026-08-30 06:37:46.079886	t	291	2026-08-31 09:08:50.323	1
269	2026-08-29	24	9	13	Night	submitted	\N	Iftikhar Ahmed	2026-08-30 06:38:55.251152	\N	2026-08-30 06:38:55.251152	t	291	2026-08-31 09:08:50.323	1
267	2026-08-29	14	2	15	Night	submitted	\N	Iftikhar Ahmed	2026-08-30 06:36:16.470087	\N	2026-08-30 06:36:16.470087	t	292	2026-08-31 09:11:42.395	1
273	2026-08-30	24	9	13	Night	submitted	\N	Iftikhar Ahmed	2026-08-31 06:08:31.230185	\N	2026-08-31 06:08:31.230185	t	293	2026-08-31 09:14:33.307	1
274	2026-08-30	29	18	13	Night	submitted	\N	Iftikhar Ahmed	2026-08-31 06:09:11.963016	\N	2026-08-31 06:09:11.963016	t	293	2026-08-31 09:14:33.307	1
272	2026-08-30	23	2	13	Night	submitted	\N	Iftikhar Ahmed	2026-08-31 06:08:01.862101	Iftikhar Ahmed	2026-08-31 06:10:05.883	t	293	2026-08-31 09:14:33.307	1
678	2026-10-12	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-13 05:58:02.281663	\N	2026-10-13 05:58:02.281663	t	452	2026-10-13 06:54:31.515	1
700	2026-10-14	15	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-15 05:14:57.671458	\N	2026-10-15 05:14:57.671458	t	468	2026-10-15 07:01:42.505	1
275	2026-08-31	22	8	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-01 04:44:26.933026	\N	2026-09-01 04:44:26.933026	t	299	2026-09-01 06:50:31.19	1
276	2026-08-31	23	7	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-01 04:45:42.937632	\N	2026-09-01 04:45:42.937632	t	299	2026-09-01 06:50:31.19	1
277	2026-08-31	24	1	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-01 04:46:34.663547	\N	2026-09-01 04:46:34.663547	t	299	2026-09-01 06:50:31.19	1
278	2026-08-31	22	2	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-01 04:48:18.618291	\N	2026-09-01 04:48:18.618291	t	299	2026-09-01 06:50:31.19	1
279	2026-08-31	23	2	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-01 04:49:05.856891	\N	2026-09-01 04:49:05.856891	t	299	2026-09-01 06:50:31.19	1
280	2026-08-31	24	9	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-01 04:49:53.24394	\N	2026-09-01 04:49:53.24394	t	299	2026-09-01 06:50:31.19	1
373	2026-09-11	15	8	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-12 05:33:18.926992	\N	2026-09-12 05:33:18.926992	t	354	2026-09-12 06:38:50.794	1
281	2026-09-01	22	8	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-02 04:50:38.735469	\N	2026-09-02 04:50:38.735469	t	301	2026-09-02 07:27:58.373	1
282	2026-09-01	23	7	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-02 04:51:29.028617	\N	2026-09-02 04:51:29.028617	t	301	2026-09-02 07:27:58.373	1
283	2026-09-01	24	1	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-02 04:52:25.524808	\N	2026-09-02 04:52:25.524808	t	301	2026-09-02 07:27:58.373	1
284	2026-09-01	22	9	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-02 04:53:08.528273	\N	2026-09-02 04:53:08.528273	t	301	2026-09-02 07:27:58.373	1
285	2026-09-01	23	9	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-02 04:53:57.073478	\N	2026-09-02 04:53:57.073478	t	301	2026-09-02 07:27:58.373	1
286	2026-09-01	24	9	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-02 04:54:40.171174	\N	2026-09-02 04:54:40.171174	t	301	2026-09-02 07:27:58.373	1
289	2026-09-02	22	8	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-03 04:55:45.238487	\N	2026-09-03 04:55:45.238487	t	306	2026-09-03 06:40:17.763	1
290	2026-09-02	23	7	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-03 04:56:32.635688	\N	2026-09-03 04:56:32.635688	t	306	2026-09-03 06:40:17.763	1
291	2026-09-02	24	1	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-03 04:57:14.813276	\N	2026-09-03 04:57:14.813276	t	306	2026-09-03 06:40:17.763	1
295	2026-09-02	22	9	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-03 05:02:08.12926	\N	2026-09-03 05:02:08.12926	t	306	2026-09-03 06:40:17.763	1
296	2026-09-02	23	2	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-03 05:02:54.157023	\N	2026-09-03 05:02:54.157023	t	306	2026-09-03 06:40:17.763	1
297	2026-09-02	24	9	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-03 05:03:39.558044	\N	2026-09-03 05:03:39.558044	t	306	2026-09-03 06:40:17.763	1
287	2026-09-02	15	8	17	Morning	submitted	\N	Iftikhar Ahmed	2026-09-03 04:52:19.158718	\N	2026-09-03 04:52:19.158718	t	307	2026-09-03 06:46:03.161	1
288	2026-09-02	18	7	17	Morning	submitted	\N	Iftikhar Ahmed	2026-09-03 04:52:58.725231	\N	2026-09-03 04:52:58.725231	t	307	2026-09-03 06:46:03.161	1
292	2026-09-02	15	2	17	Night	submitted	\N	Iftikhar Ahmed	2026-09-03 04:59:17.294043	\N	2026-09-03 04:59:17.294043	t	307	2026-09-03 06:46:03.161	1
293	2026-09-02	18	2	17	Night	submitted	\N	Iftikhar Ahmed	2026-09-03 05:00:07.629471	\N	2026-09-03 05:00:07.629471	t	307	2026-09-03 06:46:03.161	1
294	2026-09-02	21	9	17	Night	submitted	\N	Iftikhar Ahmed	2026-09-03 05:01:09.399441	\N	2026-09-03 05:01:09.399441	t	307	2026-09-03 06:46:03.161	1
298	2026-09-03	25	1	15	Morning	submitted	\N	Iftikhar Ahmed	2026-09-03 15:23:36.962888	\N	2026-09-03 15:23:36.962888	t	310	2026-09-04 06:25:03.879	1
299	2026-09-03	14	8	15	Morning	submitted	\N	Iftikhar Ahmed	2026-09-03 15:24:10.972002	\N	2026-09-03 15:24:10.972002	t	310	2026-09-04 06:25:03.879	1
306	2026-09-03	25	9	15	Night	submitted	\N	Iftikhar Ahmed	2026-09-04 05:14:18.559286	\N	2026-09-04 05:14:18.559286	t	310	2026-09-04 06:25:03.879	1
307	2026-09-03	14	9	15	Night	submitted	\N	Iftikhar Ahmed	2026-09-04 05:15:51.690749	\N	2026-09-04 05:15:51.690749	t	310	2026-09-04 06:25:03.879	1
303	2026-09-03	22	8	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-03 15:30:20.351575	\N	2026-09-03 15:30:20.351575	t	311	2026-09-04 06:27:35.345	1
304	2026-09-03	23	7	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-03 15:31:08.93545	\N	2026-09-03 15:31:08.93545	t	311	2026-09-04 06:27:35.345	1
305	2026-09-03	24	1	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-03 15:31:55.003695	\N	2026-09-03 15:31:55.003695	t	311	2026-09-04 06:27:35.345	1
311	2026-09-03	22	9	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-04 05:20:04.476544	\N	2026-09-04 05:20:04.476544	t	311	2026-09-04 06:27:35.345	1
312	2026-09-03	23	2	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-04 05:20:53.495878	\N	2026-09-04 05:20:53.495878	t	311	2026-09-04 06:27:35.345	1
313	2026-09-03	24	9	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-04 05:21:44.903005	\N	2026-09-04 05:21:44.903005	t	311	2026-09-04 06:27:35.345	1
300	2026-09-03	15	8	17	Morning	submitted	\N	Iftikhar Ahmed	2026-09-03 15:25:39.080157	\N	2026-09-03 15:25:39.080157	t	312	2026-09-04 06:30:25.261	1
301	2026-09-03	18	7	17	Morning	submitted	\N	Iftikhar Ahmed	2026-09-03 15:28:41.509102	\N	2026-09-03 15:28:41.509102	t	312	2026-09-04 06:30:25.261	1
302	2026-09-03	21	1	17	Morning	submitted	\N	Iftikhar Ahmed	2026-09-03 15:29:21.926945	\N	2026-09-03 15:29:21.926945	t	312	2026-09-04 06:30:25.261	1
308	2026-09-03	15	2	17	Night	submitted	\N	Iftikhar Ahmed	2026-09-04 05:16:48.474743	\N	2026-09-04 05:16:48.474743	t	312	2026-09-04 06:30:25.261	1
309	2026-09-03	18	2	17	Night	submitted	\N	Iftikhar Ahmed	2026-09-04 05:17:41.96003	\N	2026-09-04 05:17:41.96003	t	312	2026-09-04 06:30:25.261	1
310	2026-09-03	21	9	17	Night	submitted	\N	Iftikhar Ahmed	2026-09-04 05:19:01.387991	\N	2026-09-04 05:19:01.387991	t	312	2026-09-04 06:30:25.261	1
314	2026-09-04	25	1	15	Morning	submitted	\N	Iftikhar Ahmed	2026-09-05 05:53:24.093352	\N	2026-09-05 05:53:24.093352	t	321	2026-09-05 06:05:59.159	1
315	2026-09-04	15	8	17	Morning	submitted	\N	Iftikhar Ahmed	2026-09-05 05:54:19.183635	\N	2026-09-05 05:54:19.183635	t	322	2026-09-05 06:08:11.825	1
316	2026-09-04	21	1	17	Morning	submitted	\N	Iftikhar Ahmed	2026-09-05 05:56:29.347517	\N	2026-09-05 05:56:29.347517	t	322	2026-09-05 06:08:11.825	1
320	2026-09-04	15	9	17	Night	submitted	\N	Iftikhar Ahmed	2026-09-05 05:59:58.419463	\N	2026-09-05 05:59:58.419463	t	322	2026-09-05 06:08:11.825	1
321	2026-09-04	21	9	17	Night	submitted	\N	Iftikhar Ahmed	2026-09-05 06:00:32.674707	\N	2026-09-05 06:00:32.674707	t	322	2026-09-05 06:08:11.825	1
317	2026-09-04	22	8	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-05 05:57:30.119127	\N	2026-09-05 05:57:30.119127	t	323	2026-09-05 06:10:04.47	1
318	2026-09-04	23	7	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-05 05:58:21.372134	\N	2026-09-05 05:58:21.372134	t	323	2026-09-05 06:10:04.47	1
319	2026-09-04	24	1	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-05 05:59:05.731021	\N	2026-09-05 05:59:05.731021	t	323	2026-09-05 06:10:04.47	1
322	2026-09-04	22	9	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-05 06:01:23.855317	\N	2026-09-05 06:01:23.855317	t	323	2026-09-05 06:10:04.47	1
323	2026-09-04	24	9	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-05 06:02:29.031289	\N	2026-09-05 06:02:29.031289	t	323	2026-09-05 06:10:04.47	1
354	2026-09-09	25	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-10 04:56:59.865603	\N	2026-09-10 04:56:59.865603	t	346	2026-09-10 09:51:02.662	1
355	2026-09-09	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-10 04:57:51.693581	\N	2026-09-10 04:57:51.693581	t	346	2026-09-10 09:51:02.662	1
356	2026-09-09	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-10 05:01:20.968007	\N	2026-09-10 05:01:20.968007	t	346	2026-09-10 09:51:02.662	1
357	2026-09-09	21	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-10 05:02:08.307822	\N	2026-09-10 05:02:08.307822	t	346	2026-09-10 09:51:02.662	1
358	2026-09-09	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-10 05:03:10.246104	\N	2026-09-10 05:03:10.246104	t	346	2026-09-10 09:51:02.662	1
359	2026-09-09	14	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-10 05:03:55.900723	\N	2026-09-10 05:03:55.900723	t	346	2026-09-10 09:51:02.662	1
361	2026-09-09	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-10 05:05:55.625022	\N	2026-09-10 05:05:55.625022	t	346	2026-09-10 09:51:02.662	1
363	2026-09-10	25	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-11 04:49:13.155058	\N	2026-09-11 04:49:13.155058	t	350	2026-09-11 06:46:34.124	1
364	2026-09-10	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-11 04:50:24.126556	\N	2026-09-11 04:50:24.126556	t	350	2026-09-11 06:46:34.124	1
365	2026-09-10	18	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-11 04:51:48.438133	\N	2026-09-11 04:51:48.438133	t	350	2026-09-11 06:46:34.124	1
366	2026-09-10	21	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-11 04:52:30.956611	\N	2026-09-11 04:52:30.956611	t	350	2026-09-11 06:46:34.124	1
367	2026-09-10	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-11 04:53:37.445788	\N	2026-09-11 04:53:37.445788	t	350	2026-09-11 06:46:34.124	1
368	2026-09-10	14	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-11 04:54:40.447071	\N	2026-09-11 04:54:40.447071	t	350	2026-09-11 06:46:34.124	1
324	2026-09-05	15	7	17	Morning	submitted	\N	Iftikhar Ahmed	2026-09-06 06:50:04.595755	\N	2026-09-06 06:50:04.595755	t	325	2026-09-07 07:19:24.658	1
325	2026-09-05	22	8	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-06 06:51:07.354827	\N	2026-09-06 06:51:07.354827	t	326	2026-09-07 07:21:04.074	1
326	2026-09-05	23	7	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-06 06:51:54.987231	\N	2026-09-06 06:51:54.987231	t	326	2026-09-07 07:21:04.074	1
327	2026-09-05	24	1	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-06 06:52:38.225551	\N	2026-09-06 06:52:38.225551	t	326	2026-09-07 07:21:04.074	1
328	2026-09-05	22	9	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-06 06:53:52.770308	\N	2026-09-06 06:53:52.770308	t	326	2026-09-07 07:21:04.074	1
329	2026-09-05	23	9	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-06 06:54:40.214843	\N	2026-09-06 06:54:40.214843	t	326	2026-09-07 07:21:04.074	1
330	2026-09-05	24	2	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-06 06:55:28.568542	\N	2026-09-06 06:55:28.568542	t	326	2026-09-07 07:21:04.074	1
331	2026-09-06	22	7	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-07 05:51:36.198038	\N	2026-09-07 05:51:36.198038	t	327	2026-09-07 07:24:47.134	1
332	2026-09-06	23	7	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-07 05:52:18.218628	\N	2026-09-07 05:52:18.218628	t	327	2026-09-07 07:24:47.134	1
333	2026-09-06	24	8	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-07 05:56:35.315145	\N	2026-09-07 05:56:35.315145	t	327	2026-09-07 07:24:47.134	1
334	2026-09-06	22	2	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-07 05:57:13.692824	\N	2026-09-07 05:57:13.692824	t	327	2026-09-07 07:24:47.134	1
335	2026-09-06	23	2	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-07 05:58:24.679144	\N	2026-09-07 05:58:24.679144	t	327	2026-09-07 07:24:47.134	1
336	2026-09-06	23	9	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-07 05:59:47.316799	\N	2026-09-07 05:59:47.316799	t	327	2026-09-07 07:24:47.134	1
369	2026-09-10	18	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-11 04:55:37.925912	\N	2026-09-11 04:55:37.925912	t	350	2026-09-11 06:46:34.124	1
370	2026-09-10	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-11 04:56:13.858593	\N	2026-09-11 04:56:13.858593	t	350	2026-09-11 06:46:34.124	1
682	2026-10-12	21	9	21	Night	submitted	\N	Iftikhar Ahmed	2026-10-13 06:02:44.731436	\N	2026-10-13 06:02:44.731436	t	451	2026-10-13 06:49:35.983	1
337	2026-09-07	25	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-08 05:40:15.568506	\N	2026-09-08 05:40:15.568506	t	337	2026-09-08 07:02:26.774	1
339	2026-09-07	25	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-08 05:42:33.849408	\N	2026-09-08 05:42:33.849408	t	337	2026-09-08 07:02:26.774	1
340	2026-09-07	14	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-08 05:43:43.327311	\N	2026-09-08 05:43:43.327311	t	337	2026-09-08 07:02:26.774	1
341	2026-09-07	19	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-08 05:44:24.803462	\N	2026-09-08 05:44:24.803462	t	337	2026-09-08 07:02:26.774	1
338	2026-09-07	23	7	13	Morning	submitted	\N	Iftikhar Ahmed	2026-09-08 05:41:46.81666	\N	2026-09-08 05:41:46.81666	t	338	2026-09-08 07:04:02.309	1
342	2026-09-07	23	2	13	Night	submitted	\N	Iftikhar Ahmed	2026-09-08 05:44:52.852832	\N	2026-09-08 05:44:52.852832	t	338	2026-09-08 07:04:02.309	1
509	2026-09-25	21	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-26 05:37:57.206518	\N	2026-09-26 05:37:57.206518	t	404	2026-09-26 08:07:28.385	1
371	2026-09-11	25	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-12 05:31:49.535919	\N	2026-09-12 05:31:49.535919	t	353	2026-09-12 06:36:44.061	1
372	2026-09-11	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-12 05:32:37.365392	\N	2026-09-12 05:32:37.365392	t	353	2026-09-12 06:36:44.061	1
374	2026-09-11	18	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-12 05:33:56.351609	\N	2026-09-12 05:33:56.351609	t	353	2026-09-12 06:36:44.061	1
376	2026-09-11	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-12 05:35:25.570631	\N	2026-09-12 05:35:25.570631	t	353	2026-09-12 06:36:44.061	1
377	2026-09-11	14	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-12 05:36:16.304444	\N	2026-09-12 05:36:16.304444	t	353	2026-09-12 06:36:44.061	1
375	2026-09-11	18	8	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-12 05:34:27.552366	\N	2026-09-12 05:34:27.552366	t	354	2026-09-12 06:38:50.794	1
378	2026-09-11	15	2	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-12 05:37:07.933554	\N	2026-09-12 05:37:07.933554	t	354	2026-09-12 06:38:50.794	1
379	2026-09-11	18	2	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-12 05:38:32.746983	\N	2026-09-12 05:38:32.746983	t	354	2026-09-12 06:38:50.794	1
681	2026-10-12	18	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-13 06:02:04.667344	\N	2026-10-13 06:02:04.667344	t	452	2026-10-13 06:54:31.515	1
725	2026-10-15	24	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-16 06:17:42.607819	\N	2026-10-16 06:17:42.607819	t	476	2026-10-16 06:47:18.516	1
343	2026-09-08	25	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-09 09:01:32.416231	\N	2026-09-09 09:01:32.416231	t	340	2026-09-09 09:54:27.374	1
344	2026-09-08	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-09 09:02:34.669332	\N	2026-09-09 09:02:34.669332	t	340	2026-09-09 09:54:27.374	1
346	2026-09-08	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-09 09:04:43.856167	\N	2026-09-09 09:04:43.856167	t	340	2026-09-09 09:54:27.374	1
347	2026-09-08	19	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-09 09:10:47.886153	\N	2026-09-09 09:10:47.886153	t	340	2026-09-09 09:54:27.374	1
348	2026-09-08	21	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-09 09:12:23.519795	\N	2026-09-09 09:12:23.519795	t	340	2026-09-09 09:54:27.374	1
349	2026-09-08	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-09 09:13:39.691523	\N	2026-09-09 09:13:39.691523	t	340	2026-09-09 09:54:27.374	1
352	2026-09-08	18	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-09 09:19:28.398352	\N	2026-09-09 09:19:28.398352	t	340	2026-09-09 09:54:27.374	1
353	2026-09-08	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-09 09:20:22.740511	\N	2026-09-09 09:20:22.740511	t	340	2026-09-09 09:54:27.374	1
350	2026-09-08	14	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-09 09:14:34.791045	Iftikhar Ahmed	2026-09-09 09:42:03.392	t	340	2026-09-09 09:54:27.374	1
345	2026-09-08	15	8	17	Morning	submitted	\N	Iftikhar Ahmed	2026-09-09 09:03:26.510605	\N	2026-09-09 09:03:26.510605	t	341	2026-09-09 09:55:44.142	1
351	2026-09-08	15	2	17	Night	submitted	\N	Iftikhar Ahmed	2026-09-09 09:18:24.496474	\N	2026-09-09 09:18:24.496474	t	341	2026-09-09 09:55:44.142	1
380	2026-09-12	25	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-13 06:22:42.284583	\N	2026-09-13 06:22:42.284583	t	358	2026-09-14 08:02:52.339	1
381	2026-09-12	14	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-13 06:23:25.247977	Iftikhar Ahmed	2026-09-13 06:23:47.737	t	358	2026-09-14 08:02:52.339	1
671	2026-10-12	14	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-13 05:49:39.081719	\N	2026-10-13 05:49:39.081719	t	450	2026-10-13 06:46:15.583	1
382	2026-09-12	14	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-13 06:25:52.818888	\N	2026-09-13 06:25:52.818888	t	356	2026-09-14 07:59:33.894	1
383	2026-09-12	15	8	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-13 06:27:57.747317	\N	2026-09-13 06:27:57.747317	t	356	2026-09-14 07:59:33.894	1
384	2026-09-12	18	8	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-13 06:28:53.945611	\N	2026-09-13 06:28:53.945611	t	356	2026-09-14 07:59:33.894	1
387	2026-09-12	14	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-13 07:52:54.516791	\N	2026-09-13 07:52:54.516791	t	356	2026-09-14 07:59:33.894	1
388	2026-09-12	15	2	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-13 07:53:54.86413	\N	2026-09-13 07:53:54.86413	t	356	2026-09-14 07:59:33.894	1
389	2026-09-12	18	2	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-13 07:55:08.747807	\N	2026-09-13 07:55:08.747807	t	356	2026-09-14 07:59:33.894	1
392	2026-09-13	14	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-14 05:31:35.743593	\N	2026-09-14 05:31:35.743593	t	357	2026-09-14 08:00:54.277	1
393	2026-09-13	15	8	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-14 05:33:14.310887	\N	2026-09-14 05:33:14.310887	t	357	2026-09-14 08:00:54.277	1
394	2026-09-13	18	8	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-14 05:34:40.136886	\N	2026-09-14 05:34:40.136886	t	357	2026-09-14 08:00:54.277	1
397	2026-09-13	14	2	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-14 05:38:06.365855	\N	2026-09-14 05:38:06.365855	t	357	2026-09-14 08:00:54.277	1
398	2026-09-13	15	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-14 05:38:59.243394	\N	2026-09-14 05:38:59.243394	t	357	2026-09-14 08:00:54.277	1
399	2026-09-13	18	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-14 05:39:39.063191	\N	2026-09-14 05:39:39.063191	t	357	2026-09-14 08:00:54.277	1
385	2026-09-12	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-13 06:29:45.655186	\N	2026-09-13 06:29:45.655186	t	358	2026-09-14 08:02:52.339	1
386	2026-09-12	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-13 06:32:59.11973	\N	2026-09-13 06:32:59.11973	t	358	2026-09-14 08:02:52.339	1
390	2026-09-12	22	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-13 07:55:42.735662	\N	2026-09-13 07:55:42.735662	t	358	2026-09-14 08:02:52.339	1
391	2026-09-13	25	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-14 05:30:00.770889	\N	2026-09-14 05:30:00.770889	t	359	2026-09-14 08:04:24.642	1
395	2026-09-13	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-14 05:35:36.622506	\N	2026-09-14 05:35:36.622506	t	359	2026-09-14 08:04:24.642	1
396	2026-09-13	25	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-14 05:37:14.714055	\N	2026-09-14 05:37:14.714055	t	359	2026-09-14 08:04:24.642	1
400	2026-09-13	22	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-14 05:40:58.616971	\N	2026-09-14 05:40:58.616971	t	359	2026-09-14 08:04:24.642	1
402	2026-09-14	14	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-15 05:04:15.070535	\N	2026-09-15 05:04:15.070535	t	365	2026-09-15 06:27:01.913	1
403	2026-09-14	15	8	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-15 05:05:16.530791	\N	2026-09-15 05:05:16.530791	t	365	2026-09-15 06:27:01.913	1
404	2026-09-14	18	8	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-15 05:06:09.219855	\N	2026-09-15 05:06:09.219855	t	365	2026-09-15 06:27:01.913	1
406	2026-09-14	14	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-15 05:08:13.803946	\N	2026-09-15 05:08:13.803946	t	365	2026-09-15 06:27:01.913	1
407	2026-09-14	15	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-15 05:09:03.996406	\N	2026-09-15 05:09:03.996406	t	365	2026-09-15 06:27:01.913	1
408	2026-09-14	18	2	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-15 05:10:11.26527	\N	2026-09-15 05:10:11.26527	t	365	2026-09-15 06:27:01.913	1
401	2026-09-14	25	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-15 05:03:23.858251	\N	2026-09-15 05:03:23.858251	t	366	2026-09-15 06:35:40.057	1
405	2026-09-14	22	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-15 05:07:18.32695	\N	2026-09-15 05:07:18.32695	t	366	2026-09-15 06:35:40.057	1
413	2026-09-15	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-16 04:21:11.523971	\N	2026-09-16 04:21:11.523971	t	370	2026-09-16 05:52:32.619	1
417	2026-09-15	22	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-16 04:24:12.153693	\N	2026-09-16 04:24:12.153693	t	370	2026-09-16 05:52:32.619	1
410	2026-09-15	14	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-16 04:18:15.267953	\N	2026-09-16 04:18:15.267953	t	371	2026-09-16 05:54:29.257	1
411	2026-09-15	15	8	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-16 04:19:09.254944	\N	2026-09-16 04:19:09.254944	t	371	2026-09-16 05:54:29.257	1
412	2026-09-15	18	8	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-16 04:20:07.497952	\N	2026-09-16 04:20:07.497952	t	371	2026-09-16 05:54:29.257	1
414	2026-09-15	14	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-16 04:22:07.737354	\N	2026-09-16 04:22:07.737354	t	371	2026-09-16 05:54:29.257	1
415	2026-09-15	15	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-16 04:22:53.167109	\N	2026-09-16 04:22:53.167109	t	371	2026-09-16 05:54:29.257	1
416	2026-09-15	18	2	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-16 04:23:30.804818	\N	2026-09-16 04:23:30.804818	t	371	2026-09-16 05:54:29.257	1
418	2026-09-16	14	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-17 05:31:10.42228	\N	2026-09-17 05:31:10.42228	t	372	2026-09-17 06:03:53.163	1
419	2026-09-16	15	8	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-17 05:32:00.45604	\N	2026-09-17 05:32:00.45604	t	372	2026-09-17 06:03:53.163	1
420	2026-09-16	18	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-17 05:32:50.289789	\N	2026-09-17 05:32:50.289789	t	372	2026-09-17 06:03:53.163	1
422	2026-09-16	14	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-17 05:34:18.110437	\N	2026-09-17 05:34:18.110437	t	372	2026-09-17 06:03:53.163	1
423	2026-09-16	15	2	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-17 05:35:08.896061	\N	2026-09-17 05:35:08.896061	t	372	2026-09-17 06:03:53.163	1
424	2026-09-16	18	2	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-17 05:35:55.515443	\N	2026-09-17 05:35:55.515443	t	372	2026-09-17 06:03:53.163	1
421	2026-09-16	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-17 05:33:17.927919	\N	2026-09-17 05:33:17.927919	t	373	2026-09-17 06:07:05.78	1
425	2026-09-17	14	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-18 04:56:18.934539	\N	2026-09-18 04:56:18.934539	t	374	2026-09-18 10:34:50.008	1
426	2026-09-17	15	8	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-18 04:57:27.910321	\N	2026-09-18 04:57:27.910321	t	374	2026-09-18 10:34:50.008	1
427	2026-09-17	18	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-18 04:58:12.233452	\N	2026-09-18 04:58:12.233452	t	374	2026-09-18 10:34:50.008	1
428	2026-09-17	14	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-18 04:58:39.602906	\N	2026-09-18 04:58:39.602906	t	374	2026-09-18 10:34:50.008	1
429	2026-09-17	15	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-18 04:59:18.04637	\N	2026-09-18 04:59:18.04637	t	374	2026-09-18 10:34:50.008	1
430	2026-09-17	18	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-18 04:59:36.408559	\N	2026-09-18 04:59:36.408559	t	374	2026-09-18 10:34:50.008	1
431	2026-09-18	14	8	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-19 05:03:42.938201	\N	2026-09-19 05:03:42.938201	t	378	2026-09-19 06:28:01.84	1
432	2026-09-18	15	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-19 05:04:26.997501	\N	2026-09-19 05:04:26.997501	t	378	2026-09-19 06:28:01.84	1
433	2026-09-18	18	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-19 05:05:52.151094	\N	2026-09-19 05:05:52.151094	t	378	2026-09-19 06:28:01.84	1
436	2026-09-18	18	2	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-19 05:09:40.266034	\N	2026-09-19 05:09:40.266034	t	378	2026-09-19 06:28:01.84	1
435	2026-09-18	15	2	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-19 05:07:39.169169	Iftikhar Ahmed	2026-09-19 05:10:49.998	t	378	2026-09-19 06:28:01.84	1
484	2026-09-24	14	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-25 05:12:42.195023	\N	2026-09-25 05:12:42.195023	t	398	2026-09-25 07:21:22.112	1
485	2026-09-24	15	20	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-25 05:13:27.499211	\N	2026-09-25 05:13:27.499211	t	398	2026-09-25 07:21:22.112	1
486	2026-09-24	18	20	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-25 05:14:16.121527	\N	2026-09-25 05:14:16.121527	t	398	2026-09-25 07:21:22.112	1
489	2026-09-24	24	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-25 05:16:12.383904	\N	2026-09-25 05:16:12.383904	t	398	2026-09-25 07:21:22.112	1
490	2026-09-24	25	1	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-25 05:17:12.791009	\N	2026-09-25 05:17:12.791009	t	398	2026-09-25 07:21:22.112	1
491	2026-09-24	14	7	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-25 05:18:07.159466	\N	2026-09-25 05:18:07.159466	t	398	2026-09-25 07:21:22.112	1
434	2026-09-18	14	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-19 05:06:45.86933	Iftikhar Ahmed	2026-09-19 05:11:05.949	t	378	2026-09-19 06:28:01.84	1
487	2026-09-24	19	20	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-25 05:14:51.019124	\N	2026-09-25 05:14:51.019124	t	399	2026-09-25 07:26:30.12	1
488	2026-09-24	21	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-25 05:15:29.77875	\N	2026-09-25 05:15:29.77875	t	399	2026-09-25 07:26:30.12	1
494	2026-09-24	21	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-25 05:20:27.427231	Iftikhar Ahmed	2026-09-25 05:22:18.681	t	399	2026-09-25 07:26:30.12	1
497	2026-09-25	25	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-26 05:25:19.717696	\N	2026-09-26 05:25:19.717696	t	403	2026-09-26 08:02:23.684	1
498	2026-09-25	14	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-26 05:25:56.493613	\N	2026-09-26 05:25:56.493613	t	403	2026-09-26 08:02:23.684	1
499	2026-09-25	15	20	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-26 05:27:00.242494	\N	2026-09-26 05:27:00.242494	t	403	2026-09-26 08:02:23.684	1
500	2026-09-25	18	20	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-26 05:27:39.541535	\N	2026-09-26 05:27:39.541535	t	403	2026-09-26 08:02:23.684	1
504	2026-09-25	24	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-26 05:31:22.725554	\N	2026-09-26 05:31:22.725554	t	403	2026-09-26 08:02:23.684	1
505	2026-09-25	25	1	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-26 05:32:17.740826	\N	2026-09-26 05:32:17.740826	t	403	2026-09-26 08:02:23.684	1
506	2026-09-25	14	7	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-26 05:33:15.644109	\N	2026-09-26 05:33:15.644109	t	403	2026-09-26 08:02:23.684	1
507	2026-09-25	15	7	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-26 05:36:02.543633	\N	2026-09-26 05:36:02.543633	t	403	2026-09-26 08:02:23.684	1
508	2026-09-25	18	7	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-26 05:36:55.82065	\N	2026-09-26 05:36:55.82065	t	403	2026-09-26 08:02:23.684	1
437	2026-09-19	14	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-20 06:17:05.744509	\N	2026-09-20 06:17:05.744509	t	379	2026-09-21 07:53:43.361	1
438	2026-09-19	15	8	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-20 06:17:57.907207	\N	2026-09-20 06:17:57.907207	t	379	2026-09-21 07:53:43.361	1
439	2026-09-19	18	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-20 06:19:00.394011	\N	2026-09-20 06:19:00.394011	t	379	2026-09-21 07:53:43.361	1
442	2026-09-19	14	2	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-20 06:20:55.492232	\N	2026-09-20 06:20:55.492232	t	379	2026-09-21 07:53:43.361	1
443	2026-09-19	15	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-20 06:22:36.278057	\N	2026-09-20 06:22:36.278057	t	379	2026-09-21 07:53:43.361	1
444	2026-09-19	18	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-20 06:24:11.841279	\N	2026-09-20 06:24:11.841279	t	379	2026-09-21 07:53:43.361	1
445	2026-09-20	14	8	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-21 04:57:50.920102	\N	2026-09-21 04:57:50.920102	t	380	2026-09-21 07:56:30.508	1
446	2026-09-20	15	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-21 04:58:18.841822	\N	2026-09-21 04:58:18.841822	t	380	2026-09-21 07:56:30.508	1
447	2026-09-20	18	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-21 04:58:48.498904	\N	2026-09-21 04:58:48.498904	t	380	2026-09-21 07:56:30.508	1
448	2026-09-20	14	1	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-21 05:00:13.62772	\N	2026-09-21 05:00:13.62772	t	380	2026-09-21 07:56:30.508	1
449	2026-09-20	15	1	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-21 05:01:42.934773	\N	2026-09-21 05:01:42.934773	t	380	2026-09-21 07:56:30.508	1
450	2026-09-20	18	7	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-21 05:02:59.173741	\N	2026-09-21 05:02:59.173741	t	380	2026-09-21 07:56:30.508	1
440	2026-09-19	19	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-20 06:19:26.196503	\N	2026-09-20 06:19:26.196503	t	381	2026-09-21 07:59:07.573	1
441	2026-09-19	21	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-20 06:19:53.836483	\N	2026-09-20 06:19:53.836483	t	381	2026-09-21 07:59:07.573	1
451	2026-09-21	25	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-22 05:14:54.27992	\N	2026-09-22 05:14:54.27992	t	386	2026-09-22 05:42:42.28	1
452	2026-09-21	14	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-22 05:15:43.746008	\N	2026-09-22 05:15:43.746008	t	386	2026-09-22 05:42:42.28	1
453	2026-09-21	15	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-22 05:16:27.931637	\N	2026-09-22 05:16:27.931637	t	386	2026-09-22 05:42:42.28	1
454	2026-09-21	18	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-22 05:17:12.548536	\N	2026-09-22 05:17:12.548536	t	386	2026-09-22 05:42:42.28	1
455	2026-09-21	25	1	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-22 05:18:00.624953	\N	2026-09-22 05:18:00.624953	t	386	2026-09-22 05:42:42.28	1
456	2026-09-21	14	1	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-22 05:18:47.404198	\N	2026-09-22 05:18:47.404198	t	386	2026-09-22 05:42:42.28	1
457	2026-09-21	15	7	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-22 05:19:29.549521	\N	2026-09-22 05:19:29.549521	t	386	2026-09-22 05:42:42.28	1
458	2026-09-21	18	7	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-22 05:20:07.999457	\N	2026-09-22 05:20:07.999457	t	386	2026-09-22 05:42:42.28	1
459	2026-09-14	22	2	16	Night	submitted	\N	Khurram Hassan	2026-09-22 05:53:38.353245	\N	2026-09-22 05:53:38.353245	t	388	2026-09-22 06:02:36.298	1
460	2026-09-22	25	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-23 04:37:33.146043	\N	2026-09-23 04:37:33.146043	t	389	2026-09-23 06:39:55.173	1
461	2026-09-22	14	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-23 04:38:15.796589	\N	2026-09-23 04:38:15.796589	t	389	2026-09-23 06:39:55.173	1
462	2026-09-22	15	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-23 04:38:50.614799	\N	2026-09-23 04:38:50.614799	t	389	2026-09-23 06:39:55.173	1
463	2026-09-22	18	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-23 04:39:29.3422	\N	2026-09-23 04:39:29.3422	t	389	2026-09-23 06:39:55.173	1
464	2026-09-22	25	1	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-23 04:40:21.727617	\N	2026-09-23 04:40:21.727617	t	389	2026-09-23 06:39:55.173	1
465	2026-09-22	14	1	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-23 04:41:02.691455	\N	2026-09-23 04:41:02.691455	t	389	2026-09-23 06:39:55.173	1
466	2026-09-22	15	7	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-23 04:41:58.312408	\N	2026-09-23 04:41:58.312408	t	389	2026-09-23 06:39:55.173	1
467	2026-09-22	18	7	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-23 04:42:48.449846	\N	2026-09-23 04:42:48.449846	t	389	2026-09-23 06:39:55.173	1
468	2026-09-22	21	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-23 04:43:28.539423	\N	2026-09-23 04:43:28.539423	t	390	2026-09-23 06:41:09.65	1
469	2026-09-23	25	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-24 05:08:23.437537	\N	2026-09-24 05:08:23.437537	t	392	2026-09-24 07:09:14.697	1
470	2026-09-23	14	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-24 05:09:38.684363	\N	2026-09-24 05:09:38.684363	t	392	2026-09-24 07:09:14.697	1
471	2026-09-23	15	20	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-24 05:10:24.656258	\N	2026-09-24 05:10:24.656258	t	392	2026-09-24 07:09:14.697	1
472	2026-09-23	18	20	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-24 05:11:22.416977	\N	2026-09-24 05:11:22.416977	t	392	2026-09-24 07:09:14.697	1
475	2026-09-23	24	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-24 05:14:02.251101	\N	2026-09-24 05:14:02.251101	t	392	2026-09-24 07:09:14.697	1
476	2026-09-23	25	1	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-24 05:17:19.428044	\N	2026-09-24 05:17:19.428044	t	392	2026-09-24 07:09:14.697	1
477	2026-09-23	14	7	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-24 05:19:33.959135	\N	2026-09-24 05:19:33.959135	t	392	2026-09-24 07:09:14.697	1
478	2026-09-23	15	7	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-24 05:20:30.323928	\N	2026-09-24 05:20:30.323928	t	392	2026-09-24 07:09:14.697	1
479	2026-09-23	18	7	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-24 05:21:19.822946	\N	2026-09-24 05:21:19.822946	t	392	2026-09-24 07:09:14.697	1
481	2026-09-23	24	1	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-24 05:24:42.524893	\N	2026-09-24 05:24:42.524893	t	392	2026-09-24 07:09:14.697	1
473	2026-09-23	19	20	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-24 05:12:25.711941	\N	2026-09-24 05:12:25.711941	t	393	2026-09-24 07:11:33.56	1
474	2026-09-23	21	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-24 05:13:15.736301	\N	2026-09-24 05:13:15.736301	t	393	2026-09-24 07:11:33.56	1
480	2026-09-23	21	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-24 05:22:20.649999	\N	2026-09-24 05:22:20.649999	t	393	2026-09-24 07:11:33.56	1
482	2026-09-23	29	18	14	Morning	submitted	\N	Khurram Hassan	2026-09-24 07:17:58.475403	\N	2026-09-24 07:17:58.475403	t	\N	2026-09-24 07:19:18.129	1
483	2026-09-24	25	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-25 05:11:20.917583	\N	2026-09-25 05:11:20.917583	t	398	2026-09-25 07:21:22.112	1
492	2026-09-24	15	7	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-25 05:19:02.140968	\N	2026-09-25 05:19:02.140968	t	398	2026-09-25 07:21:22.112	1
493	2026-09-24	18	7	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-25 05:19:44.698957	\N	2026-09-25 05:19:44.698957	t	398	2026-09-25 07:21:22.112	1
495	2026-09-24	24	1	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-25 05:21:21.188327	\N	2026-09-25 05:21:21.188327	t	398	2026-09-25 07:21:22.112	1
510	2026-09-25	24	1	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-26 05:38:58.201978	\N	2026-09-26 05:38:58.201978	t	403	2026-09-26 08:02:23.684	1
503	2026-09-25	22	20	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-26 05:30:15.97516	\N	2026-09-26 05:30:15.97516	t	404	2026-09-26 08:07:28.385	1
501	2026-09-25	19	20	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-26 05:28:07.27644	Iftikhar Ahmed	2026-09-26 05:40:06.298	t	404	2026-09-26 08:07:28.385	1
677	2026-10-12	24	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-13 05:55:30.063991	\N	2026-10-13 05:55:30.063991	t	450	2026-10-13 06:46:15.583	1
679	2026-10-12	14	46	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-13 05:58:57.586743	\N	2026-10-13 05:58:57.586743	t	450	2026-10-13 06:46:15.583	1
683	2026-10-12	24	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-13 06:03:32.786141	\N	2026-10-13 06:03:32.786141	t	450	2026-10-13 06:46:15.583	1
705	2026-10-14	24	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-15 05:23:05.510666	\N	2026-10-15 05:23:05.510666	t	466	2026-10-15 06:55:59.946	1
511	2026-09-26	25	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-27 10:19:55.59282	\N	2026-09-27 10:19:55.59282	t	406	2026-09-28 06:43:33.216	1
512	2026-09-26	14	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-27 10:20:53.488316	\N	2026-09-27 10:20:53.488316	t	406	2026-09-28 06:43:33.216	1
513	2026-09-26	15	20	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-27 10:21:44.95564	\N	2026-09-27 10:21:44.95564	t	406	2026-09-28 06:43:33.216	1
514	2026-09-26	18	20	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-27 10:22:25.41471	\N	2026-09-27 10:22:25.41471	t	406	2026-09-28 06:43:33.216	1
519	2026-09-26	24	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-27 10:27:22.450215	\N	2026-09-27 10:27:22.450215	t	406	2026-09-28 06:43:33.216	1
520	2026-09-26	25	1	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-27 10:27:46.90704	\N	2026-09-27 10:27:46.90704	t	406	2026-09-28 06:43:33.216	1
525	2026-09-26	24	1	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-27 10:32:12.721474	\N	2026-09-27 10:32:12.721474	t	406	2026-09-28 06:43:33.216	1
515	2026-09-26	18	20	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-27 10:22:46.189125	\N	2026-09-27 10:22:46.189125	t	407	2026-09-28 07:42:03.837	1
516	2026-09-26	19	20	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-27 10:23:39.164147	\N	2026-09-27 10:23:39.164147	t	407	2026-09-28 07:42:03.837	1
517	2026-09-26	21	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-27 10:24:29.521687	\N	2026-09-27 10:24:29.521687	t	407	2026-09-28 07:42:03.837	1
518	2026-09-26	22	20	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-27 10:26:25.865741	\N	2026-09-27 10:26:25.865741	t	407	2026-09-28 07:42:03.837	1
521	2026-09-26	18	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-27 10:28:41.836799	\N	2026-09-27 10:28:41.836799	t	407	2026-09-28 07:42:03.837	1
522	2026-09-26	19	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-27 10:29:39.74333	\N	2026-09-27 10:29:39.74333	t	407	2026-09-28 07:42:03.837	1
523	2026-09-26	21	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-27 10:30:21.337081	\N	2026-09-27 10:30:21.337081	t	407	2026-09-28 07:42:03.837	1
524	2026-09-26	22	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-27 10:31:21.224684	\N	2026-09-27 10:31:21.224684	t	407	2026-09-28 07:42:03.837	1
707	2026-10-14	14	46	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-15 05:25:32.108483	\N	2026-10-15 05:25:32.108483	t	466	2026-10-15 06:55:59.946	1
708	2026-10-14	15	46	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-15 05:26:31.66149	\N	2026-10-15 05:26:31.66149	t	466	2026-10-15 06:55:59.946	1
712	2026-10-14	24	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-15 05:30:06.690799	\N	2026-10-15 05:30:06.690799	t	466	2026-10-15 06:55:59.946	1
702	2026-10-14	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-15 05:19:25.679285	\N	2026-10-15 05:19:25.679285	t	468	2026-10-15 07:01:42.505	1
704	2026-10-14	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-15 05:22:17.088326	\N	2026-10-15 05:22:17.088326	t	468	2026-10-15 07:01:42.505	1
706	2026-10-14	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-15 05:23:56.947109	\N	2026-10-15 05:23:56.947109	t	468	2026-10-15 07:01:42.505	1
709	2026-10-14	18	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-15 05:27:20.894004	\N	2026-10-15 05:27:20.894004	t	468	2026-10-15 07:01:42.505	1
711	2026-10-14	22	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-15 05:29:17.090635	\N	2026-10-15 05:29:17.090635	t	468	2026-10-15 07:01:42.505	1
703	2026-10-14	21	1	21	Morning	submitted	\N	Iftikhar Ahmed	2026-10-15 05:21:30.294289	\N	2026-10-15 05:21:30.294289	t	469	2026-10-15 07:03:21.973	1
710	2026-10-14	21	9	21	Night	submitted	\N	Iftikhar Ahmed	2026-10-15 05:27:52.968605	\N	2026-10-15 05:27:52.968605	t	469	2026-10-15 07:03:21.973	1
727	2026-10-16	14	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-17 05:23:04.741434	\N	2026-10-17 05:23:04.741434	t	482	2026-10-17 06:20:06.917	1
729	2026-10-16	18	7	17	Morning	submitted	\N	Iftikhar Ahmed	2026-10-17 05:25:28.880338	\N	2026-10-17 05:25:28.880338	t	483	2026-10-17 06:22:39.022	1
730	2026-10-16	21	1	21	Morning	submitted	\N	Iftikhar Ahmed	2026-10-17 05:26:09.403038	\N	2026-10-17 05:26:09.403038	t	484	2026-10-17 06:23:51.544	1
757	2026-10-18	25	1	16	Morning	submitted	\N	Khurram Hassan	2026-10-19 07:50:28.807342	\N	2026-10-19 07:50:28.807342	t	491	2026-10-19 09:50:22.342	1
531	2026-09-27	25	1	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-28 08:01:18.391712	\N	2026-09-28 08:01:18.391712	t	408	2026-09-29 06:39:22.366	1
537	2026-09-27	24	1	14	Night	submitted	\N	Iftikhar Ahmed	2026-09-28 08:08:11.863295	\N	2026-09-28 08:08:11.863295	t	408	2026-09-29 06:39:22.366	1
526	2026-09-27	15	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-28 07:56:15.068036	\N	2026-09-28 07:56:15.068036	t	409	2026-09-29 06:57:52.058	1
527	2026-09-27	18	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-28 07:57:51.464605	\N	2026-09-28 07:57:51.464605	t	409	2026-09-29 06:57:52.058	1
528	2026-09-27	19	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-28 07:58:38.666462	\N	2026-09-28 07:58:38.666462	t	409	2026-09-29 06:57:52.058	1
529	2026-09-27	21	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-28 07:59:37.895976	\N	2026-09-28 07:59:37.895976	t	409	2026-09-29 06:57:52.058	1
530	2026-09-27	22	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-28 08:00:21.684671	\N	2026-09-28 08:00:21.684671	t	409	2026-09-29 06:57:52.058	1
532	2026-09-27	15	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-28 08:02:20.263414	\N	2026-09-28 08:02:20.263414	t	409	2026-09-29 06:57:52.058	1
533	2026-09-27	18	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-28 08:03:15.840225	\N	2026-09-28 08:03:15.840225	t	409	2026-09-29 06:57:52.058	1
534	2026-09-27	19	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-28 08:05:24.41467	\N	2026-09-28 08:05:24.41467	t	409	2026-09-29 06:57:52.058	1
535	2026-09-27	21	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-28 08:06:17.823147	\N	2026-09-28 08:06:17.823147	t	409	2026-09-29 06:57:52.058	1
536	2026-09-27	22	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-28 08:07:06.799973	\N	2026-09-28 08:07:06.799973	t	409	2026-09-29 06:57:52.058	1
538	2026-09-28	25	9	14	Morning	submitted	\N	Iftikhar Ahmed	2026-09-28 08:14:34.873776	\N	2026-09-28 08:14:34.873776	t	410	2026-09-29 06:59:07.32	1
540	2026-09-28	15	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-29 05:18:02.494828	\N	2026-09-29 05:18:02.494828	t	412	2026-09-29 07:36:02.181	1
541	2026-09-28	18	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-29 05:20:03.140013	\N	2026-09-29 05:20:03.140013	t	412	2026-09-29 07:36:02.181	1
542	2026-09-28	19	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-29 05:21:09.891523	\N	2026-09-29 05:21:09.891523	t	412	2026-09-29 07:36:02.181	1
543	2026-09-28	21	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-29 05:21:54.557759	\N	2026-09-29 05:21:54.557759	t	412	2026-09-29 07:36:02.181	1
544	2026-09-28	22	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-29 05:22:42.887551	\N	2026-09-29 05:22:42.887551	t	412	2026-09-29 07:36:02.181	1
545	2026-09-28	15	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-29 05:23:25.747746	\N	2026-09-29 05:23:25.747746	t	412	2026-09-29 07:36:02.181	1
546	2026-09-28	18	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-29 05:24:31.163508	\N	2026-09-29 05:24:31.163508	t	412	2026-09-29 07:36:02.181	1
547	2026-09-28	19	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-29 05:25:50.119306	\N	2026-09-29 05:25:50.119306	t	412	2026-09-29 07:36:02.181	1
548	2026-09-28	22	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-29 05:26:36.661539	\N	2026-09-29 05:26:36.661539	t	412	2026-09-29 07:36:02.181	1
496	2026-09-24	29	18	22	Morning	submitted	\N	Khurram Hassan	2026-09-25 07:25:17.789648	Khurram Hassan	2026-09-25 07:42:25.183	t	413	2026-09-29 07:44:07.567	1
675	2026-10-12	21	7	21	Morning	submitted	\N	Iftikhar Ahmed	2026-10-13 05:52:29.789101	\N	2026-10-13 05:52:29.789101	t	451	2026-10-13 06:49:35.983	1
670	2026-10-12	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-13 05:48:48.087163	\N	2026-10-13 05:48:48.087163	t	452	2026-10-13 06:54:31.515	1
672	2026-10-12	15	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-13 05:50:29.271855	\N	2026-10-13 05:50:29.271855	t	452	2026-10-13 06:54:31.515	1
673	2026-10-12	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-13 05:51:09.678404	\N	2026-10-13 05:51:09.678404	t	452	2026-10-13 06:54:31.515	1
674	2026-10-12	19	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-13 05:51:49.226725	\N	2026-10-13 05:51:49.226725	t	452	2026-10-13 06:54:31.515	1
680	2026-10-12	15	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-13 05:59:48.632338	\N	2026-10-13 05:59:48.632338	t	452	2026-10-13 06:54:31.515	1
699	2026-10-14	14	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-15 05:14:20.980552	\N	2026-10-15 05:14:20.980552	t	466	2026-10-15 06:55:59.946	1
701	2026-10-14	15	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-15 05:15:45.073516	\N	2026-10-15 05:15:45.073516	t	466	2026-10-15 06:55:59.946	1
555	2026-09-30	14	30	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-01 05:26:16.399653	\N	2026-10-01 05:26:16.399653	t	421	2026-10-01 06:26:18.144	1
556	2026-09-30	15	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-01 05:29:46.946326	\N	2026-10-01 05:29:46.946326	t	421	2026-10-01 06:26:18.144	1
558	2026-09-30	22	30	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-01 05:31:36.643954	\N	2026-10-01 05:31:36.643954	t	421	2026-10-01 06:26:18.144	1
559	2026-09-30	14	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-01 05:32:51.571835	\N	2026-10-01 05:32:51.571835	t	421	2026-10-01 06:26:18.144	1
560	2026-09-30	15	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-01 05:34:08.007716	\N	2026-10-01 05:34:08.007716	t	421	2026-10-01 06:26:18.144	1
561	2026-09-30	18	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-01 05:34:56.527885	\N	2026-10-01 05:34:56.527885	t	421	2026-10-01 06:26:18.144	1
562	2026-09-30	22	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-01 05:35:59.118356	\N	2026-10-01 05:35:59.118356	t	421	2026-10-01 06:26:18.144	1
557	2026-09-30	18	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-01 05:30:44.245179	Iftikhar Ahmed	2026-10-01 05:39:10.275	t	421	2026-10-01 06:26:18.144	1
549	2026-09-29	15	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-30 05:30:01.986237	\N	2026-09-30 05:30:01.986237	t	422	2026-10-01 06:33:20.734	1
550	2026-09-29	18	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-30 05:30:48.181348	\N	2026-09-30 05:30:48.181348	t	422	2026-10-01 06:33:20.734	1
551	2026-09-29	22	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-09-30 05:31:29.462812	\N	2026-09-30 05:31:29.462812	t	422	2026-10-01 06:33:20.734	1
552	2026-09-29	15	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-30 05:32:38.17242	\N	2026-09-30 05:32:38.17242	t	422	2026-10-01 06:33:20.734	1
553	2026-09-29	18	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-30 05:33:22.943902	\N	2026-09-30 05:33:22.943902	t	422	2026-10-01 06:33:20.734	1
554	2026-09-29	22	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-09-30 05:34:09.582362	\N	2026-09-30 05:34:09.582362	t	422	2026-10-01 06:33:20.734	1
731	2026-10-16	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-17 05:26:50.207227	\N	2026-10-17 05:26:50.207227	t	481	2026-10-17 06:17:08.701	1
733	2026-10-16	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-17 05:28:44.430083	\N	2026-10-17 05:28:44.430083	t	481	2026-10-17 06:17:08.701	1
738	2026-10-16	22	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-17 05:34:46.528018	\N	2026-10-17 05:34:46.528018	t	481	2026-10-17 06:17:08.701	1
732	2026-10-16	24	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-17 05:27:36.664638	\N	2026-10-17 05:27:36.664638	t	482	2026-10-17 06:20:06.917	1
734	2026-10-16	14	46	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-17 05:30:02.495828	\N	2026-10-17 05:30:02.495828	t	482	2026-10-17 06:20:06.917	1
735	2026-10-16	15	46	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-17 05:30:47.462039	\N	2026-10-17 05:30:47.462039	t	482	2026-10-17 06:20:06.917	1
563	2026-10-01	14	30	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-02 05:34:39.633814	\N	2026-10-02 05:34:39.633814	t	423	2026-10-02 07:01:55.711	1
564	2026-10-01	15	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-02 05:35:37.890683	\N	2026-10-02 05:35:37.890683	t	423	2026-10-02 07:01:55.711	1
565	2026-10-01	18	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-02 05:36:22.384184	\N	2026-10-02 05:36:22.384184	t	423	2026-10-02 07:01:55.711	1
566	2026-10-01	22	30	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-02 05:37:09.783354	\N	2026-10-02 05:37:09.783354	t	423	2026-10-02 07:01:55.711	1
567	2026-10-01	14	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-02 05:38:15.971208	\N	2026-10-02 05:38:15.971208	t	423	2026-10-02 07:01:55.711	1
568	2026-10-01	15	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-02 05:39:10.804242	\N	2026-10-02 05:39:10.804242	t	423	2026-10-02 07:01:55.711	1
569	2026-10-01	18	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-02 05:40:04.629888	\N	2026-10-02 05:40:04.629888	t	423	2026-10-02 07:01:55.711	1
570	2026-10-01	22	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-02 05:41:07.345269	\N	2026-10-02 05:41:07.345269	t	423	2026-10-02 07:01:55.711	1
739	2026-10-16	24	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-17 05:36:01.418814	\N	2026-10-17 05:36:01.418814	t	482	2026-10-17 06:20:06.917	1
736	2026-10-16	18	46	17	Night	submitted	\N	Iftikhar Ahmed	2026-10-17 05:32:26.342231	\N	2026-10-17 05:32:26.342231	t	483	2026-10-17 06:22:39.022	1
737	2026-10-16	21	9	21	Night	submitted	\N	Iftikhar Ahmed	2026-10-17 05:34:02.149511	\N	2026-10-17 05:34:02.149511	t	484	2026-10-17 06:23:51.544	1
571	2026-10-02	14	30	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-03 06:10:33.999335	\N	2026-10-03 06:10:33.999335	t	425	2026-10-03 08:00:22.382	1
572	2026-10-02	15	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-03 06:12:01.409152	\N	2026-10-03 06:12:01.409152	t	425	2026-10-03 08:00:22.382	1
573	2026-10-02	18	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-03 06:12:50.027279	\N	2026-10-03 06:12:50.027279	t	425	2026-10-03 08:00:22.382	1
574	2026-10-02	21	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-03 06:13:31.903203	\N	2026-10-03 06:13:31.903203	t	425	2026-10-03 08:00:22.382	1
575	2026-10-02	22	30	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-03 06:14:20.181537	\N	2026-10-03 06:14:20.181537	t	425	2026-10-03 08:00:22.382	1
576	2026-10-02	14	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-03 06:15:59.420095	\N	2026-10-03 06:15:59.420095	t	425	2026-10-03 08:00:22.382	1
577	2026-10-02	15	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-03 06:16:52.186835	\N	2026-10-03 06:16:52.186835	t	425	2026-10-03 08:00:22.382	1
578	2026-10-02	18	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-03 06:17:39.976253	\N	2026-10-03 06:17:39.976253	t	425	2026-10-03 08:00:22.382	1
758	2026-10-18	14	1	14	Morning	submitted	\N	Khurram Hassan	2026-10-19 07:51:44.378677	\N	2026-10-19 07:51:44.378677	t	488	2026-10-19 09:42:31.106	1
759	2026-10-18	15	7	14	Morning	submitted	\N	Khurram Hassan	2026-10-19 07:52:32.399347	\N	2026-10-19 07:52:32.399347	t	488	2026-10-19 09:42:31.106	1
744	2026-10-17	18	7	17	Morning	submitted	\N	Khurram Hassan	2026-10-19 07:26:16.633513	\N	2026-10-19 07:26:16.633513	t	489	2026-10-19 09:45:26.497	1
746	2026-10-17	22	7	16	Morning	submitted	\N	Khurram Hassan	2026-10-19 07:27:51.530922	\N	2026-10-19 07:27:51.530922	t	490	2026-10-19 09:49:05.646	1
749	2026-10-17	25	20	16	Night	submitted	\N	Khurram Hassan	2026-10-19 07:30:31.504049	\N	2026-10-19 07:30:31.504049	t	490	2026-10-19 09:49:05.646	1
760	2026-10-18	18	7	16	Morning	submitted	\N	Khurram Hassan	2026-10-19 07:53:04.800123	\N	2026-10-19 07:53:04.800123	t	491	2026-10-19 09:50:22.342	1
745	2026-10-17	21	1	21	Morning	submitted	\N	Khurram Hassan	2026-10-19 07:27:04.62914	\N	2026-10-19 07:27:04.62914	t	492	2026-10-19 09:51:29.085	1
761	2026-10-18	21	1	21	Morning	submitted	\N	Khurram Hassan	2026-10-19 07:53:55.300372	\N	2026-10-19 07:53:55.300372	t	493	2026-10-19 09:53:16.526	1
579	2026-10-02	21	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-03 06:18:12.318667	\N	2026-10-03 06:18:12.318667	t	425	2026-10-03 08:00:22.382	1
580	2026-10-02	22	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-03 06:18:58.489635	\N	2026-10-03 06:18:58.489635	t	425	2026-10-03 08:00:22.382	1
685	2026-10-13	14	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-14 06:07:19.988366	\N	2026-10-14 06:07:19.988366	t	458	2026-10-14 09:39:34.604	1
684	2026-10-13	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-14 06:06:28.386207	\N	2026-10-14 06:06:28.386207	t	459	2026-10-14 09:43:12.886	1
686	2026-10-13	15	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-14 06:08:15.896225	\N	2026-10-14 06:08:15.896225	t	459	2026-10-14 09:43:12.886	1
698	2026-10-14	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-15 05:13:21.073943	\N	2026-10-15 05:13:21.073943	t	468	2026-10-15 07:01:42.505	1
726	2026-10-16	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-17 05:22:15.297385	\N	2026-10-17 05:22:15.297385	t	481	2026-10-17 06:17:08.701	1
581	2026-10-03	14	30	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-04 05:17:17.223417	\N	2026-10-04 05:17:17.223417	t	426	2026-10-05 06:50:08.501	1
582	2026-10-03	15	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-04 05:18:16.929101	\N	2026-10-04 05:18:16.929101	t	426	2026-10-05 06:50:08.501	1
583	2026-10-03	18	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-04 05:20:43.80722	\N	2026-10-04 05:20:43.80722	t	426	2026-10-05 06:50:08.501	1
584	2026-10-03	21	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-04 05:21:23.16264	\N	2026-10-04 05:21:23.16264	t	426	2026-10-05 06:50:08.501	1
585	2026-10-03	22	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-04 05:22:09.578522	\N	2026-10-04 05:22:09.578522	t	426	2026-10-05 06:50:08.501	1
586	2026-10-03	14	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-04 06:28:30.706465	\N	2026-10-04 06:28:30.706465	t	426	2026-10-05 06:50:08.501	1
587	2026-10-03	15	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-04 06:30:03.39998	\N	2026-10-04 06:30:03.39998	t	426	2026-10-05 06:50:08.501	1
588	2026-10-03	18	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-04 06:31:04.724932	\N	2026-10-04 06:31:04.724932	t	426	2026-10-05 06:50:08.501	1
589	2026-10-03	21	7	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-04 06:31:47.662378	\N	2026-10-04 06:31:47.662378	t	426	2026-10-05 06:50:08.501	1
590	2026-10-03	22	1	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-04 06:32:48.028686	\N	2026-10-04 06:32:48.028686	t	426	2026-10-05 06:50:08.501	1
591	2026-10-04	14	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-05 05:51:43.797266	\N	2026-10-05 05:51:43.797266	t	427	2026-10-05 06:57:16.34	1
592	2026-10-04	14	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-05 05:52:00.816441	\N	2026-10-05 05:52:00.816441	t	427	2026-10-05 06:57:16.34	1
593	2026-10-04	15	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-05 05:52:41.276718	\N	2026-10-05 05:52:41.276718	t	427	2026-10-05 06:57:16.34	1
594	2026-10-04	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-05 05:53:29.162787	\N	2026-10-05 05:53:29.162787	t	427	2026-10-05 06:57:16.34	1
595	2026-10-04	21	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-05 05:53:58.002823	\N	2026-10-05 05:53:58.002823	t	427	2026-10-05 06:57:16.34	1
596	2026-10-04	22	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-05 05:54:26.223315	\N	2026-10-05 05:54:26.223315	t	427	2026-10-05 06:57:16.34	1
597	2026-10-04	14	30	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-05 05:55:43.283734	\N	2026-10-05 05:55:43.283734	t	427	2026-10-05 06:57:16.34	1
598	2026-10-04	15	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-05 05:56:48.577325	\N	2026-10-05 05:56:48.577325	t	427	2026-10-05 06:57:16.34	1
599	2026-10-04	18	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-05 05:57:47.127555	\N	2026-10-05 05:57:47.127555	t	427	2026-10-05 06:57:16.34	1
600	2026-10-04	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-05 05:58:32.200984	\N	2026-10-05 05:58:32.200984	t	427	2026-10-05 06:57:16.34	1
601	2026-10-04	22	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-05 05:59:23.910409	\N	2026-10-05 05:59:23.910409	t	427	2026-10-05 06:57:16.34	1
602	2026-10-05	14	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-06 05:13:03.115378	\N	2026-10-06 05:13:03.115378	t	428	2026-10-06 10:16:19.882	1
603	2026-10-05	15	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-06 05:13:58.306602	\N	2026-10-06 05:13:58.306602	t	428	2026-10-06 10:16:19.882	1
604	2026-10-05	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-06 05:14:47.270911	\N	2026-10-06 05:14:47.270911	t	428	2026-10-06 10:16:19.882	1
605	2026-10-05	21	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-06 05:15:27.881095	\N	2026-10-06 05:15:27.881095	t	428	2026-10-06 10:16:19.882	1
606	2026-10-05	22	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-06 05:16:16.184007	\N	2026-10-06 05:16:16.184007	t	428	2026-10-06 10:16:19.882	1
607	2026-10-05	14	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-06 05:17:45.277627	\N	2026-10-06 05:17:45.277627	t	428	2026-10-06 10:16:19.882	1
608	2026-10-05	15	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-06 05:18:35.701439	\N	2026-10-06 05:18:35.701439	t	428	2026-10-06 10:16:19.882	1
609	2026-10-05	18	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-06 05:19:15.303879	\N	2026-10-06 05:19:15.303879	t	428	2026-10-06 10:16:19.882	1
610	2026-10-05	22	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-06 05:20:03.948708	\N	2026-10-06 05:20:03.948708	t	428	2026-10-06 10:16:19.882	1
611	2026-10-06	14	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-07 05:23:33.898802	\N	2026-10-07 05:23:33.898802	t	434	2026-10-07 07:33:45.701	1
612	2026-10-06	15	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-07 05:31:57.09665	\N	2026-10-07 05:31:57.09665	t	434	2026-10-07 07:33:45.701	1
613	2026-10-06	21	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-07 05:32:21.523935	\N	2026-10-07 05:32:21.523935	t	434	2026-10-07 07:33:45.701	1
614	2026-10-06	22	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-07 05:33:14.399352	\N	2026-10-07 05:33:14.399352	t	434	2026-10-07 07:33:45.701	1
615	2026-10-06	14	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-07 05:34:21.191417	\N	2026-10-07 05:34:21.191417	t	434	2026-10-07 07:33:45.701	1
616	2026-10-06	15	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-07 05:35:07.079636	\N	2026-10-07 05:35:07.079636	t	434	2026-10-07 07:33:45.701	1
617	2026-10-06	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-07 05:36:23.70505	\N	2026-10-07 05:36:23.70505	t	434	2026-10-07 07:33:45.701	1
625	2026-10-08	14	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-09 05:19:56.391503	\N	2026-10-09 05:19:56.391503	t	435	2026-10-09 07:07:32.174	1
626	2026-10-08	15	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-09 05:23:27.894698	\N	2026-10-09 05:23:27.894698	t	435	2026-10-09 07:07:32.174	1
627	2026-10-08	21	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-09 05:24:15.825204	\N	2026-10-09 05:24:15.825204	t	435	2026-10-09 07:07:32.174	1
628	2026-10-08	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-09 05:25:07.787644	\N	2026-10-09 05:25:07.787644	t	435	2026-10-09 07:07:32.174	1
629	2026-10-08	14	9	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-09 05:26:07.884466	\N	2026-10-09 05:26:07.884466	t	435	2026-10-09 07:07:32.174	1
630	2026-10-08	15	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-09 05:34:51.032264	\N	2026-10-09 05:34:51.032264	t	435	2026-10-09 07:07:32.174	1
631	2026-10-08	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-09 05:35:17.66762	\N	2026-10-09 05:35:17.66762	t	435	2026-10-09 07:07:32.174	1
632	2026-10-08	22	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-09 05:36:15.417611	\N	2026-10-09 05:36:15.417611	t	435	2026-10-09 07:07:32.174	1
618	2026-10-07	14	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-08 05:33:56.957957	\N	2026-10-08 05:33:56.957957	t	436	2026-10-09 07:12:57.102	1
619	2026-10-07	15	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-08 05:34:40.274215	\N	2026-10-08 05:34:40.274215	t	436	2026-10-09 07:12:57.102	1
620	2026-10-07	21	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-08 05:35:22.888374	\N	2026-10-08 05:35:22.888374	t	436	2026-10-09 07:12:57.102	1
621	2026-10-07	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-08 05:35:42.606911	\N	2026-10-08 05:35:42.606911	t	436	2026-10-09 07:12:57.102	1
622	2026-10-07	14	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-08 05:37:20.085905	\N	2026-10-08 05:37:20.085905	t	436	2026-10-09 07:12:57.102	1
623	2026-10-07	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-08 05:42:00.089663	\N	2026-10-08 05:42:00.089663	t	436	2026-10-09 07:12:57.102	1
624	2026-10-07	22	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-08 05:42:57.767373	\N	2026-10-08 05:42:57.767373	t	436	2026-10-09 07:12:57.102	1
633	2026-10-09	14	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-10 05:38:59.433443	\N	2026-10-10 05:38:59.433443	t	442	2026-10-10 07:09:39.769	1
634	2026-10-09	15	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-10 05:39:40.692559	\N	2026-10-10 05:39:40.692559	t	442	2026-10-10 07:09:39.769	1
635	2026-10-09	15	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-10 05:40:11.980139	\N	2026-10-10 05:40:11.980139	t	442	2026-10-10 07:09:39.769	1
636	2026-10-09	19	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-10 05:40:38.061065	\N	2026-10-10 05:40:38.061065	t	442	2026-10-10 07:09:39.769	1
637	2026-10-09	21	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-10 05:41:48.533339	\N	2026-10-10 05:41:48.533339	t	442	2026-10-10 07:09:39.769	1
638	2026-10-09	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-10 05:44:12.238154	\N	2026-10-10 05:44:12.238154	t	442	2026-10-10 07:09:39.769	1
639	2026-10-09	14	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-10 05:50:11.804627	\N	2026-10-10 05:50:11.804627	t	442	2026-10-10 07:09:39.769	1
641	2026-10-09	15	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-10 05:56:28.940819	\N	2026-10-10 05:56:28.940819	t	442	2026-10-10 07:09:39.769	1
642	2026-10-09	19	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-10 05:57:03.689535	\N	2026-10-10 05:57:03.689535	t	442	2026-10-10 07:09:39.769	1
643	2026-10-09	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-10 05:57:30.62659	\N	2026-10-10 05:57:30.62659	t	442	2026-10-10 07:09:39.769	1
644	2026-10-09	22	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-10 05:58:17.195512	\N	2026-10-10 05:58:17.195512	t	442	2026-10-10 07:09:39.769	1
690	2026-10-13	24	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-14 06:11:30.096003	\N	2026-10-14 06:11:30.096003	t	458	2026-10-14 09:39:34.604	1
692	2026-10-13	14	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-14 06:15:57.087243	\N	2026-10-14 06:15:57.087243	t	458	2026-10-14 09:39:34.604	1
697	2026-10-13	24	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-14 06:19:49.500422	\N	2026-10-14 06:19:49.500422	t	458	2026-10-14 09:39:34.604	1
655	2026-10-11	25	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-12 05:39:27.888172	\N	2026-10-12 05:39:27.888172	t	446	2026-10-12 07:20:07.082	1
689	2026-10-13	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-14 06:10:31.707869	\N	2026-10-14 06:10:31.707869	t	459	2026-10-14 09:43:12.886	1
691	2026-10-13	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-14 06:12:53.24747	\N	2026-10-14 06:12:53.24747	t	459	2026-10-14 09:43:12.886	1
693	2026-10-13	15	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-14 06:17:00.389353	\N	2026-10-14 06:17:00.389353	t	459	2026-10-14 09:43:12.886	1
694	2026-10-13	18	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-14 06:17:51.508161	\N	2026-10-14 06:17:51.508161	t	459	2026-10-14 09:43:12.886	1
696	2026-10-13	22	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-14 06:19:04.742219	\N	2026-10-14 06:19:04.742219	t	459	2026-10-14 09:43:12.886	1
688	2026-10-13	21	1	21	Morning	submitted	\N	Iftikhar Ahmed	2026-10-14 06:09:42.996215	\N	2026-10-14 06:09:42.996215	t	460	2026-10-14 09:44:28.48	1
695	2026-10-13	21	9	21	Night	submitted	\N	Iftikhar Ahmed	2026-10-14 06:18:28.266304	Iftikhar Ahmed	2026-10-14 06:21:05.928	t	460	2026-10-14 09:44:28.48	1
645	2026-10-10	14	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-11 08:02:42.713412	\N	2026-10-11 08:02:42.713412	t	444	2026-10-12 07:16:19.628	1
646	2026-10-10	15	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-11 08:03:27.527774	\N	2026-10-11 08:03:27.527774	t	444	2026-10-12 07:16:19.628	1
647	2026-10-10	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-11 08:04:32.725364	\N	2026-10-11 08:04:32.725364	t	444	2026-10-12 07:16:19.628	1
648	2026-10-10	19	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-11 08:05:26.295781	\N	2026-10-11 08:05:26.295781	t	444	2026-10-12 07:16:19.628	1
649	2026-10-10	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-11 08:05:46.971164	\N	2026-10-11 08:05:46.971164	t	444	2026-10-12 07:16:19.628	1
650	2026-10-10	14	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-11 08:06:36.383308	\N	2026-10-11 08:06:36.383308	t	444	2026-10-12 07:16:19.628	1
651	2026-10-10	15	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-11 08:07:38.093703	\N	2026-10-11 08:07:38.093703	t	444	2026-10-12 07:16:19.628	1
653	2026-10-10	22	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-11 08:09:17.722094	\N	2026-10-11 08:09:17.722094	t	444	2026-10-12 07:16:19.628	1
652	2026-10-10	18	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-11 08:08:32.282388	Iftikhar Ahmed	2026-10-11 08:10:16.984	t	444	2026-10-12 07:16:19.628	1
656	2026-10-11	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-12 05:40:00.198818	\N	2026-10-12 05:40:00.198818	t	445	2026-10-12 07:18:39.18	1
657	2026-10-11	14	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-12 05:40:36.769552	\N	2026-10-12 05:40:36.769552	t	445	2026-10-12 07:18:39.18	1
659	2026-10-11	15	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-12 05:46:22.78145	\N	2026-10-12 05:46:22.78145	t	445	2026-10-12 07:18:39.18	1
660	2026-10-11	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-12 05:47:06.99287	\N	2026-10-12 05:47:06.99287	t	445	2026-10-12 07:18:39.18	1
661	2026-10-11	19	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-12 05:47:52.570368	\N	2026-10-12 05:47:52.570368	t	445	2026-10-12 07:18:39.18	1
662	2026-10-11	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-12 05:48:46.363919	\N	2026-10-12 05:48:46.363919	t	445	2026-10-12 07:18:39.18	1
664	2026-10-11	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-12 06:06:50.703258	\N	2026-10-12 06:06:50.703258	t	445	2026-10-12 07:18:39.18	1
666	2026-10-11	15	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-12 06:08:39.50614	\N	2026-10-12 06:08:39.50614	t	445	2026-10-12 07:18:39.18	1
667	2026-10-11	18	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-12 06:09:22.087376	\N	2026-10-12 06:09:22.087376	t	445	2026-10-12 07:18:39.18	1
668	2026-10-11	22	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-12 06:09:59.475116	\N	2026-10-12 06:09:59.475116	t	445	2026-10-12 07:18:39.18	1
658	2026-10-11	14	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-12 05:41:17.878233	\N	2026-10-12 05:41:17.878233	t	446	2026-10-12 07:20:07.082	1
663	2026-10-11	24	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-12 05:49:51.80563	\N	2026-10-12 05:49:51.80563	t	446	2026-10-12 07:20:07.082	1
665	2026-10-11	14	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-12 06:07:46.470475	\N	2026-10-12 06:07:46.470475	t	446	2026-10-12 07:20:07.082	1
669	2026-10-11	24	9	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-12 06:10:46.075937	\N	2026-10-12 06:10:46.075937	t	446	2026-10-12 07:20:07.082	1
713	2026-10-15	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-16 06:08:03.178275	\N	2026-10-16 06:08:03.178275	t	475	2026-10-16 06:45:34.406	1
718	2026-10-15	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-16 06:11:43.999604	\N	2026-10-16 06:11:43.999604	t	475	2026-10-16 06:45:34.406	1
720	2026-10-15	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-16 06:13:27.710619	\N	2026-10-16 06:13:27.710619	t	475	2026-10-16 06:45:34.406	1
724	2026-10-15	22	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-16 06:16:42.22741	\N	2026-10-16 06:16:42.22741	t	475	2026-10-16 06:45:34.406	1
714	2026-10-15	14	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-16 06:09:00.262245	\N	2026-10-16 06:09:00.262245	t	476	2026-10-16 06:47:18.516	1
715	2026-10-15	15	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-16 06:09:46.587612	\N	2026-10-16 06:09:46.587612	t	476	2026-10-16 06:47:18.516	1
716	2026-10-15	18	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-16 06:10:18.778107	\N	2026-10-16 06:10:18.778107	t	476	2026-10-16 06:47:18.516	1
719	2026-10-15	24	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-16 06:12:32.96459	\N	2026-10-16 06:12:32.96459	t	476	2026-10-16 06:47:18.516	1
717	2026-10-15	21	1	21	Morning	submitted	\N	Iftikhar Ahmed	2026-10-16 06:10:48.907811	\N	2026-10-16 06:10:48.907811	t	477	2026-10-16 06:48:37.964	1
723	2026-10-15	21	9	21	Night	submitted	\N	Iftikhar Ahmed	2026-10-16 06:15:44.095828	\N	2026-10-16 06:15:44.095828	t	477	2026-10-16 06:48:37.964	1
728	2026-10-16	15	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-17 05:23:49.325815	\N	2026-10-17 05:23:49.325815	t	482	2026-10-17 06:20:06.917	1
754	2026-10-17	22	46	16	Night	submitted	\N	Khurram Hassan	2026-10-19 07:34:45.282949	\N	2026-10-19 07:34:45.282949	t	490	2026-10-19 09:49:05.646	1
762	2026-10-18	22	7	16	Morning	submitted	\N	Khurram Hassan	2026-10-19 07:54:43.246088	\N	2026-10-19 07:54:43.246088	t	491	2026-10-19 09:50:22.342	1
753	2026-10-17	21	20	21	Night	submitted	\N	Khurram Hassan	2026-10-19 07:33:42.384211	\N	2026-10-19 07:33:42.384211	t	492	2026-10-19 09:51:29.085	1
742	2026-10-17	14	1	14	Morning	submitted	\N	Khurram Hassan	2026-10-19 07:24:16.608197	\N	2026-10-19 07:24:16.608197	t	487	2026-10-19 09:39:47.824	1
743	2026-10-17	15	7	14	Morning	submitted	\N	Khurram Hassan	2026-10-19 07:25:10.488846	\N	2026-10-19 07:25:10.488846	t	487	2026-10-19 09:39:47.824	1
747	2026-10-17	23	7	14	Morning	submitted	\N	Khurram Hassan	2026-10-19 07:28:36.979627	\N	2026-10-19 07:28:36.979627	t	487	2026-10-19 09:39:47.824	1
748	2026-10-17	24	1	14	Morning	submitted	\N	Khurram Hassan	2026-10-19 07:29:32.935526	\N	2026-10-19 07:29:32.935526	t	487	2026-10-19 09:39:47.824	1
750	2026-10-17	14	20	14	Night	submitted	\N	Khurram Hassan	2026-10-19 07:31:24.63917	\N	2026-10-19 07:31:24.63917	t	487	2026-10-19 09:39:47.824	1
751	2026-10-17	15	46	14	Night	submitted	\N	Khurram Hassan	2026-10-19 07:32:14.517041	\N	2026-10-19 07:32:14.517041	t	487	2026-10-19 09:39:47.824	1
755	2026-10-17	23	46	14	Night	submitted	\N	Khurram Hassan	2026-10-19 07:35:35.846942	\N	2026-10-19 07:35:35.846942	t	487	2026-10-19 09:39:47.824	1
756	2026-10-17	24	20	14	Night	submitted	\N	Khurram Hassan	2026-10-19 07:36:28.119469	\N	2026-10-19 07:36:28.119469	t	487	2026-10-19 09:39:47.824	1
763	2026-10-18	23	7	14	Morning	submitted	\N	Khurram Hassan	2026-10-19 07:55:29.598512	\N	2026-10-19 07:55:29.598512	t	488	2026-10-19 09:42:31.106	1
764	2026-10-18	24	1	14	Morning	submitted	\N	Khurram Hassan	2026-10-19 07:56:19.591738	\N	2026-10-19 07:56:19.591738	t	488	2026-10-19 09:42:31.106	1
766	2026-10-18	14	20	14	Night	submitted	\N	Khurram Hassan	2026-10-19 07:58:09.400956	\N	2026-10-19 07:58:09.400956	t	488	2026-10-19 09:42:31.106	1
767	2026-10-18	15	46	14	Night	submitted	\N	Khurram Hassan	2026-10-19 07:58:54.919536	\N	2026-10-19 07:58:54.919536	t	488	2026-10-19 09:42:31.106	1
771	2026-10-18	23	46	14	Night	submitted	\N	Khurram Hassan	2026-10-19 08:03:35.832594	\N	2026-10-19 08:03:35.832594	t	488	2026-10-19 09:42:31.106	1
772	2026-10-18	24	20	14	Night	submitted	\N	Khurram Hassan	2026-10-19 08:04:35.610354	\N	2026-10-19 08:04:35.610354	t	488	2026-10-19 09:42:31.106	1
752	2026-10-17	18	46	17	Night	submitted	\N	Khurram Hassan	2026-10-19 07:33:05.624927	\N	2026-10-19 07:33:05.624927	t	489	2026-10-19 09:45:26.497	1
740	2026-10-17	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-19 07:13:58.806161	\N	2026-10-19 07:13:58.806161	t	490	2026-10-19 09:49:05.646	1
765	2026-10-18	25	20	16	Night	submitted	\N	Khurram Hassan	2026-10-19 07:57:22.736826	\N	2026-10-19 07:57:22.736826	t	491	2026-10-19 09:50:22.342	1
768	2026-10-18	18	46	16	Night	submitted	\N	Khurram Hassan	2026-10-19 08:00:39.863706	\N	2026-10-19 08:00:39.863706	t	491	2026-10-19 09:50:22.342	1
770	2026-10-18	22	46	16	Night	submitted	\N	Khurram Hassan	2026-10-19 08:02:40.03652	\N	2026-10-19 08:02:40.03652	t	491	2026-10-19 09:50:22.342	1
769	2026-10-18	21	20	21	Night	submitted	\N	Khurram Hassan	2026-10-19 08:01:42.023431	\N	2026-10-19 08:01:42.023431	t	493	2026-10-19 09:53:16.526	1
774	2026-10-19	14	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-20 06:38:08.930927	\N	2026-10-20 06:38:08.930927	t	499	2026-10-20 07:12:09.823	1
775	2026-10-19	15	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-20 06:38:57.726635	\N	2026-10-20 06:38:57.726635	t	499	2026-10-20 07:12:09.823	1
779	2026-10-19	23	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-20 06:42:41.712479	\N	2026-10-20 06:42:41.712479	t	499	2026-10-20 07:12:09.823	1
780	2026-10-19	24	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-20 06:43:32.37848	\N	2026-10-20 06:43:32.37848	t	499	2026-10-20 07:12:09.823	1
782	2026-10-19	14	47	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-20 06:45:13.629232	\N	2026-10-20 06:45:13.629232	t	499	2026-10-20 07:12:09.823	1
783	2026-10-19	15	47	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-20 06:45:56.638441	\N	2026-10-20 06:45:56.638441	t	499	2026-10-20 07:12:09.823	1
787	2026-10-19	23	46	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-20 06:49:21.649195	\N	2026-10-20 06:49:21.649195	t	499	2026-10-20 07:12:09.823	1
788	2026-10-19	24	20	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-20 06:50:07.018041	\N	2026-10-20 06:50:07.018041	t	499	2026-10-20 07:12:09.823	1
773	2026-10-19	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-20 06:36:56.631237	\N	2026-10-20 06:36:56.631237	t	500	2026-10-20 07:12:53.026	1
776	2026-10-19	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-20 06:40:07.792761	\N	2026-10-20 06:40:07.792761	t	500	2026-10-20 07:12:53.026	1
778	2026-10-19	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-20 06:41:53.520901	\N	2026-10-20 06:41:53.520901	t	500	2026-10-20 07:12:53.026	1
781	2026-10-19	25	20	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-20 06:44:27.206384	\N	2026-10-20 06:44:27.206384	t	500	2026-10-20 07:12:53.026	1
784	2026-10-19	18	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-20 06:47:01.109208	\N	2026-10-20 06:47:01.109208	t	500	2026-10-20 07:12:53.026	1
786	2026-10-19	22	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-20 06:48:30.227564	\N	2026-10-20 06:48:30.227564	t	500	2026-10-20 07:12:53.026	1
777	2026-10-19	21	1	21	Morning	submitted	\N	Iftikhar Ahmed	2026-10-20 06:41:00.131308	\N	2026-10-20 06:41:00.131308	t	501	2026-10-20 07:13:14.503	1
785	2026-10-19	21	20	21	Night	submitted	\N	Iftikhar Ahmed	2026-10-20 06:47:37.227194	\N	2026-10-20 06:47:37.227194	t	501	2026-10-20 07:13:14.503	1
790	2026-10-20	14	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-21 06:47:46.008247	\N	2026-10-21 06:47:46.008247	t	513	2026-10-21 09:27:18.122	1
791	2026-10-20	15	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-21 06:48:40.54885	\N	2026-10-21 06:48:40.54885	t	513	2026-10-21 09:27:18.122	1
796	2026-10-20	23	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-21 06:52:21.026869	\N	2026-10-21 06:52:21.026869	t	513	2026-10-21 09:27:18.122	1
797	2026-10-20	24	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-21 06:53:28.667317	\N	2026-10-21 06:53:28.667317	t	513	2026-10-21 09:27:18.122	1
799	2026-10-20	14	47	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-21 07:09:49.524483	\N	2026-10-21 07:09:49.524483	t	513	2026-10-21 09:27:18.122	1
800	2026-10-20	15	47	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-21 07:10:29.041463	\N	2026-10-21 07:10:29.041463	t	513	2026-10-21 09:27:18.122	1
804	2026-10-20	23	46	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-21 07:14:21.494138	\N	2026-10-21 07:14:21.494138	t	513	2026-10-21 09:27:18.122	1
805	2026-10-20	24	20	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-21 07:15:09.951038	\N	2026-10-21 07:15:09.951038	t	513	2026-10-21 09:27:18.122	1
789	2026-10-20	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-21 06:42:10.935721	\N	2026-10-21 06:42:10.935721	t	514	2026-10-21 09:29:08.213	1
792	2026-10-20	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-21 06:49:16.15872	\N	2026-10-21 06:49:16.15872	t	514	2026-10-21 09:29:08.213	1
795	2026-10-20	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-21 06:51:31.889154	\N	2026-10-21 06:51:31.889154	t	514	2026-10-21 09:29:08.213	1
798	2026-10-20	25	20	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-21 07:09:02.857655	\N	2026-10-21 07:09:02.857655	t	514	2026-10-21 09:29:08.213	1
803	2026-10-20	22	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-21 07:13:37.107629	\N	2026-10-21 07:13:37.107629	t	514	2026-10-21 09:29:08.213	1
793	2026-10-20	18	7	17	Morning	submitted	\N	Iftikhar Ahmed	2026-10-21 06:50:17.31348	\N	2026-10-21 06:50:17.31348	t	515	2026-10-21 09:30:09.102	1
801	2026-10-20	18	46	17	Night	submitted	\N	Iftikhar Ahmed	2026-10-21 07:11:39.127832	\N	2026-10-21 07:11:39.127832	t	515	2026-10-21 09:30:09.102	1
794	2026-10-20	21	1	21	Morning	submitted	\N	Iftikhar Ahmed	2026-10-21 06:50:45.290465	\N	2026-10-21 06:50:45.290465	t	516	2026-10-21 09:47:32.58	1
802	2026-10-20	21	20	21	Night	submitted	\N	Iftikhar Ahmed	2026-10-21 07:12:57.920538	\N	2026-10-21 07:12:57.920538	t	516	2026-10-21 09:47:32.58	1
806	2026-10-21	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-22 05:59:21.242842	\N	2026-10-22 05:59:21.242842	t	520	2026-10-22 06:56:18.174	1
807	2026-10-21	14	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-22 06:01:18.451075	\N	2026-10-22 06:01:18.451075	t	521	2026-10-22 07:00:00.814	1
808	2026-10-21	15	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-22 06:02:08.237759	\N	2026-10-22 06:02:08.237759	t	521	2026-10-22 07:00:00.814	1
811	2026-10-21	21	20	21	Morning	submitted	\N	Iftikhar Ahmed	2026-10-22 06:04:08.104707	\N	2026-10-22 06:04:08.104707	t	522	2026-10-22 07:00:35.297	1
809	2026-10-21	18	7	17	Morning	submitted	\N	Iftikhar Ahmed	2026-10-22 06:02:57.599006	\N	2026-10-22 06:02:57.599006	t	523	2026-10-22 07:01:17.69	1
859	2026-10-24	18	7	17	Morning	submitted	\N	Iftikhar Ahmed	2026-10-25 05:45:10.552011	\N	2026-10-25 05:45:10.552011	t	551	2026-10-26 10:36:44.544	1
867	2026-10-24	18	46	17	Night	submitted	\N	Iftikhar Ahmed	2026-10-25 05:51:36.544454	\N	2026-10-25 05:51:36.544454	t	551	2026-10-26 10:36:44.544	1
810	2026-10-21	20	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-22 06:03:33.349234	\N	2026-10-22 06:03:33.349234	t	520	2026-10-22 06:56:18.174	1
812	2026-10-21	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-22 06:04:53.40181	Iftikhar Ahmed	2026-10-22 06:52:13.652	t	520	2026-10-22 06:56:18.174	1
815	2026-10-21	25	20	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-22 06:11:20.100906	\N	2026-10-22 06:11:20.100906	t	520	2026-10-22 06:56:18.174	1
820	2026-10-21	22	47	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-22 06:15:14.734475	\N	2026-10-22 06:15:14.734475	t	520	2026-10-22 06:56:18.174	1
813	2026-10-21	23	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-22 06:06:28.603177	\N	2026-10-22 06:06:28.603177	t	521	2026-10-22 07:00:00.814	1
814	2026-10-21	24	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-22 06:07:46.790994	\N	2026-10-22 06:07:46.790994	t	521	2026-10-22 07:00:00.814	1
816	2026-10-21	14	47	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-22 06:12:04.604554	\N	2026-10-22 06:12:04.604554	t	521	2026-10-22 07:00:00.814	1
817	2026-10-21	15	47	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-22 06:12:51.603427	\N	2026-10-22 06:12:51.603427	t	521	2026-10-22 07:00:00.814	1
821	2026-10-21	23	46	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-22 06:50:03.435113	\N	2026-10-22 06:50:03.435113	t	521	2026-10-22 07:00:00.814	1
822	2026-10-21	24	20	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-22 06:50:57.652307	\N	2026-10-22 06:50:57.652307	t	521	2026-10-22 07:00:00.814	1
819	2026-10-21	21	20	21	Night	submitted	\N	Iftikhar Ahmed	2026-10-22 06:14:27.373338	\N	2026-10-22 06:14:27.373338	t	522	2026-10-22 07:00:35.297	1
818	2026-10-21	18	46	17	Night	submitted	\N	Iftikhar Ahmed	2026-10-22 06:13:52.880528	\N	2026-10-22 06:13:52.880528	t	523	2026-10-22 07:01:17.69	1
824	2026-10-22	14	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-23 05:14:43.395423	\N	2026-10-23 05:14:43.395423	t	525	2026-10-23 07:25:51.701	1
825	2026-10-22	15	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-23 05:19:21.797719	\N	2026-10-23 05:19:21.797719	t	525	2026-10-23 07:25:51.701	1
829	2026-10-22	23	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-23 05:22:41.502924	\N	2026-10-23 05:22:41.502924	t	525	2026-10-23 07:25:51.701	1
830	2026-10-22	24	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-23 05:24:26.444659	\N	2026-10-23 05:24:26.444659	t	525	2026-10-23 07:25:51.701	1
832	2026-10-22	14	47	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-23 05:26:12.91398	\N	2026-10-23 05:26:12.91398	t	525	2026-10-23 07:25:51.701	1
833	2026-10-22	15	47	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-23 05:26:55.239029	\N	2026-10-23 05:26:55.239029	t	525	2026-10-23 07:25:51.701	1
837	2026-10-22	23	46	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-23 05:30:03.091611	\N	2026-10-23 05:30:03.091611	t	525	2026-10-23 07:25:51.701	1
838	2026-10-22	24	20	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-23 05:30:52.118481	\N	2026-10-23 05:30:52.118481	t	525	2026-10-23 07:25:51.701	1
823	2026-10-22	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-23 05:13:57.900075	\N	2026-10-23 05:13:57.900075	t	526	2026-10-23 07:26:48.243	1
828	2026-10-22	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-23 05:21:52.720967	\N	2026-10-23 05:21:52.720967	t	526	2026-10-23 07:26:48.243	1
831	2026-10-22	25	20	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-23 05:25:27.529661	\N	2026-10-23 05:25:27.529661	t	526	2026-10-23 07:26:48.243	1
836	2026-10-22	22	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-23 05:29:23.007889	\N	2026-10-23 05:29:23.007889	t	526	2026-10-23 07:26:48.243	1
827	2026-10-22	21	1	21	Morning	submitted	\N	Iftikhar Ahmed	2026-10-23 05:20:49.240057	\N	2026-10-23 05:20:49.240057	t	527	2026-10-23 07:28:47.706	1
835	2026-10-22	21	20	21	Night	submitted	\N	Iftikhar Ahmed	2026-10-23 05:28:23.111827	\N	2026-10-23 05:28:23.111827	t	527	2026-10-23 07:28:47.706	1
826	2026-10-22	18	7	17	Morning	submitted	\N	Iftikhar Ahmed	2026-10-23 05:20:08.64999	\N	2026-10-23 05:20:08.64999	t	528	2026-10-23 07:30:21.634	1
834	2026-10-22	18	46	17	Night	submitted	\N	Iftikhar Ahmed	2026-10-23 05:27:45.923977	\N	2026-10-23 05:27:45.923977	t	528	2026-10-23 07:30:21.634	1
839	2026-10-23	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-24 05:23:47.33671	\N	2026-10-24 05:23:47.33671	t	532	2026-10-24 07:25:29.61	1
844	2026-10-23	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-24 05:29:10.313631	\N	2026-10-24 05:29:10.313631	t	532	2026-10-24 07:25:29.61	1
848	2026-10-23	25	20	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-24 05:32:48.914992	\N	2026-10-24 05:32:48.914992	t	532	2026-10-24 07:25:29.61	1
840	2026-10-23	14	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-24 05:25:17.199556	\N	2026-10-24 05:25:17.199556	t	533	2026-10-24 07:26:46.198	1
841	2026-10-23	15	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-24 05:26:50.943821	\N	2026-10-24 05:26:50.943821	t	533	2026-10-24 07:26:46.198	1
846	2026-10-23	23	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-24 05:30:27.123554	\N	2026-10-24 05:30:27.123554	t	533	2026-10-24 07:26:46.198	1
847	2026-10-23	24	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-24 05:31:34.082804	\N	2026-10-24 05:31:34.082804	t	533	2026-10-24 07:26:46.198	1
849	2026-10-23	14	47	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-24 05:35:19.237122	\N	2026-10-24 05:35:19.237122	t	533	2026-10-24 07:26:46.198	1
850	2026-10-23	15	47	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-24 05:36:09.127804	\N	2026-10-24 05:36:09.127804	t	533	2026-10-24 07:26:46.198	1
853	2026-10-23	23	46	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-24 05:38:20.824454	\N	2026-10-24 05:38:20.824454	t	533	2026-10-24 07:26:46.198	1
854	2026-10-23	24	20	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-24 05:39:11.430399	\N	2026-10-24 05:39:11.430399	t	533	2026-10-24 07:26:46.198	1
843	2026-10-23	21	1	21	Morning	submitted	\N	Iftikhar Ahmed	2026-10-24 05:28:22.533848	\N	2026-10-24 05:28:22.533848	t	534	2026-10-24 07:28:38.293	1
852	2026-10-23	21	47	21	Night	submitted	\N	Iftikhar Ahmed	2026-10-24 05:37:30.764445	Iftikhar Ahmed	2026-10-24 05:40:21.21	t	534	2026-10-24 07:28:38.293	1
842	2026-10-23	18	7	17	Morning	submitted	\N	Iftikhar Ahmed	2026-10-24 05:27:45.316984	\N	2026-10-24 05:27:45.316984	t	535	2026-10-24 07:50:13.194	1
845	2026-10-23	22	7	17	Morning	submitted	\N	Iftikhar Ahmed	2026-10-24 05:29:29.994961	\N	2026-10-24 05:29:29.994961	t	535	2026-10-24 07:50:13.194	1
851	2026-10-23	18	46	17	Night	submitted	\N	Iftikhar Ahmed	2026-10-24 05:36:38.3676	\N	2026-10-24 05:36:38.3676	t	535	2026-10-24 07:50:13.194	1
855	2026-10-24	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-25 05:42:39.757286	\N	2026-10-25 05:42:39.757286	t	546	2026-10-26 10:30:25.524	1
861	2026-10-24	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-25 05:46:20.422442	\N	2026-10-25 05:46:20.422442	t	546	2026-10-26 10:30:25.524	1
869	2026-10-24	22	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-25 05:53:12.963914	\N	2026-10-25 05:53:12.963914	t	546	2026-10-26 10:30:25.524	1
872	2026-10-25	25	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-26 09:00:32.497087	\N	2026-10-26 09:00:32.497087	t	547	2026-10-26 10:31:35.83	1
860	2026-10-24	21	1	21	Morning	submitted	\N	Iftikhar Ahmed	2026-10-25 05:45:48.786009	\N	2026-10-25 05:45:48.786009	t	548	2026-10-26 10:32:28.396	1
868	2026-10-24	21	20	21	Night	submitted	\N	Iftikhar Ahmed	2026-10-25 05:52:18.834078	\N	2026-10-25 05:52:18.834078	t	548	2026-10-26 10:32:28.396	1
875	2026-10-25	18	7	17	Morning	submitted	\N	Iftikhar Ahmed	2026-10-26 09:03:43.732577	\N	2026-10-26 09:03:43.732577	t	552	2026-10-26 10:37:51.765	1
883	2026-10-25	18	46	17	Night	submitted	\N	Iftikhar Ahmed	2026-10-26 09:10:13.196488	\N	2026-10-26 09:10:13.196488	t	552	2026-10-26 10:37:51.765	1
876	2026-10-25	21	1	21	Morning	submitted	\N	Iftikhar Ahmed	2026-10-26 09:04:16.41762	\N	2026-10-26 09:04:16.41762	f	\N	\N	1
884	2026-10-25	21	20	21	Night	submitted	\N	Iftikhar Ahmed	2026-10-26 09:10:42.317508	\N	2026-10-26 09:10:42.317508	f	\N	\N	1
856	2026-10-24	25	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-25 05:42:56.556099	\N	2026-10-25 05:42:56.556099	t	544	2026-10-26 10:10:54.305	1
857	2026-10-24	14	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-25 05:43:45.818578	\N	2026-10-25 05:43:45.818578	t	544	2026-10-26 10:10:54.305	1
858	2026-10-24	15	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-25 05:44:34.469265	\N	2026-10-25 05:44:34.469265	t	544	2026-10-26 10:10:54.305	1
862	2026-10-24	23	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-25 05:47:12.352095	\N	2026-10-25 05:47:12.352095	t	544	2026-10-26 10:10:54.305	1
863	2026-10-24	24	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-25 05:48:02.893971	\N	2026-10-25 05:48:02.893971	t	544	2026-10-26 10:10:54.305	1
864	2026-10-24	25	20	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-25 05:48:58.163769	\N	2026-10-25 05:48:58.163769	t	544	2026-10-26 10:10:54.305	1
865	2026-10-24	14	47	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-25 05:49:46.056482	\N	2026-10-25 05:49:46.056482	t	544	2026-10-26 10:10:54.305	1
866	2026-10-24	15	47	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-25 05:50:30.65374	\N	2026-10-25 05:50:30.65374	t	544	2026-10-26 10:10:54.305	1
870	2026-10-24	23	46	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-25 05:54:45.480981	\N	2026-10-25 05:54:45.480981	t	544	2026-10-26 10:10:54.305	1
871	2026-10-24	24	20	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-25 05:55:36.27549	\N	2026-10-25 05:55:36.27549	t	544	2026-10-26 10:10:54.305	1
877	2026-10-25	22	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-10-26 09:05:01.746384	\N	2026-10-26 09:05:01.746384	t	545	2026-10-26 10:28:57.397	1
885	2026-10-25	22	46	16	Night	submitted	\N	Iftikhar Ahmed	2026-10-26 09:12:02.69052	\N	2026-10-26 09:12:02.69052	t	545	2026-10-26 10:28:57.397	1
873	2026-10-25	14	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-26 09:02:11.814229	\N	2026-10-26 09:02:11.814229	t	547	2026-10-26 10:31:35.83	1
874	2026-10-25	15	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-26 09:02:59.208544	\N	2026-10-26 09:02:59.208544	t	547	2026-10-26 10:31:35.83	1
878	2026-10-25	23	7	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-26 09:05:46.998678	\N	2026-10-26 09:05:46.998678	t	547	2026-10-26 10:31:35.83	1
879	2026-10-25	24	1	14	Morning	submitted	\N	Iftikhar Ahmed	2026-10-26 09:06:37.31507	\N	2026-10-26 09:06:37.31507	t	547	2026-10-26 10:31:35.83	1
880	2026-10-25	25	20	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-26 09:07:32.634609	\N	2026-10-26 09:07:32.634609	t	547	2026-10-26 10:31:35.83	1
881	2026-10-25	14	20	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-26 09:08:30.109633	\N	2026-10-26 09:08:30.109633	t	547	2026-10-26 10:31:35.83	1
882	2026-10-25	15	46	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-26 09:09:16.318458	\N	2026-10-26 09:09:16.318458	t	547	2026-10-26 10:31:35.83	1
886	2026-10-25	23	46	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-26 09:12:43.016781	\N	2026-10-26 09:12:43.016781	t	547	2026-10-26 10:31:35.83	1
887	2026-10-25	24	20	14	Night	submitted	\N	Iftikhar Ahmed	2026-10-26 09:13:30.908987	\N	2026-10-26 09:13:30.908987	t	547	2026-10-26 10:31:35.83	1
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
26	12	2026-08-28	1000	\N	2026-08-31 10:04:58.473345	1
27	10	2026-08-28	3000	\N	2026-08-31 10:05:14.936079	1
28	1	2026-08-28	1000	\N	2026-08-31 10:05:28.99471	1
29	8	2026-08-31	3000	\N	2026-09-04 13:21:11.919565	1
30	2	2026-09-05	2000	\N	2026-09-05 13:00:02.867026	1
31	15	2026-09-10	5000	\N	2026-09-15 14:49:19.927928	1
32	8	2026-09-10	2000	\N	2026-09-15 14:49:33.592794	1
33	16	2026-09-15	6000	\N	2026-09-15 14:49:54.659309	1
34	9	2026-09-16	5000	\N	2026-09-16 11:03:52.404123	1
35	10	2026-09-09	1000	\N	2026-09-18 12:04:49.359388	1
36	10	2026-09-17	1000	\N	2026-09-18 12:04:59.572816	1
38	15	2026-09-21	2500	\N	2026-09-21 13:07:43.944665	1
39	1	2026-09-21	10500	\N	2026-09-21 13:08:00.944633	1
40	14	2026-09-21	2500	\N	2026-09-22 14:03:16.351494	1
41	14	2026-09-22	15000	\N	2026-09-22 14:03:25.805079	1
42	16	2026-09-22	15000	\N	2026-09-22 14:05:33.049676	1
44	12	2026-09-22	35000	\N	2026-09-22 14:07:59.116537	1
45	15	2026-09-22	12500	\N	2026-09-22 14:12:05.908385	1
46	8	2026-09-22	29190	Full & Finall	2026-09-22 14:15:03.060717	1
47	9	2026-09-22	15000	\N	2026-09-22 14:15:12.405426	1
48	11	2026-09-22	10000	\N	2026-09-22 14:17:55.247786	1
49	10	2026-09-22	35000	\N	2026-09-22 14:20:49.156505	1
50	10	2026-09-22	500	\N	2026-09-22 14:20:54.178365	1
51	2	2026-09-22	15000	\N	2026-09-22 14:24:28.272389	1
52	7	2026-09-22	10000	\N	2026-09-22 14:24:56.06211	1
53	10	2026-09-18	2000	\N	2026-09-22 14:25:59.253767	1
54	2	2026-09-24	5000	\N	2026-09-24 11:38:35.926333	1
55	1	2026-09-22	9000	\N	2026-09-25 09:34:50.781038	1
56	20	2026-09-26	3000	\N	2026-09-28 07:13:27.967881	1
57	9	2026-09-28	5000	\N	2026-09-28 13:04:47.926628	1
58	15	2026-09-28	2000	\N	2026-09-28 13:04:59.480015	1
59	1	2026-09-29	2000	\N	2026-09-30 12:25:43.171858	1
60	16	2026-10-09	10000	For Kid sunnat 	2026-10-09 11:16:41.613739	1
61	1	2026-10-08	3000	\N	2026-10-09 11:51:26.028036	1
62	15	2026-10-10	3000	Dauter's illness	2026-10-10 11:54:32.293964	1
63	1	2026-10-10	15000	Wife's delivery	2026-10-10 11:55:18.483819	1
64	30	2026-10-05	8731	To take wife to hospital	2026-10-12 05:02:20.684712	1
65	10	2026-10-01	3000	\N	2026-10-13 11:10:53.390641	1
66	10	2026-10-13	20000	\N	2026-10-20 09:29:40.150738	1
67	47	2026-10-20	1000	\N	2026-10-20 15:25:11.254333	1
68	20	2026-10-21	10000	\N	2026-10-21 12:08:38.327109	1
69	15	2026-10-21	17000	\N	2026-10-21 12:08:48.127267	1
70	11	2026-10-21	15000	\N	2026-10-21 12:09:02.617892	1
71	12	2026-10-21	35000	\N	2026-10-21 12:09:15.397257	1
72	46	2026-10-21	25000	\N	2026-10-21 12:09:27.114654	1
73	7	2026-10-21	15000	\N	2026-10-21 12:09:36.848494	1
74	1	2026-10-21	8000	\N	2026-10-21 12:09:48.337493	1
\.


--
-- Data for Name: employee_loan_deductions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_loan_deductions (tenant_id, id, employee_id, header_id, month, year, date, amount, created_at) FROM stdin;
\.


--
-- Data for Name: employee_loans; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_loans (tenant_id, id, employee_id, date, amount, notes, created_at) FROM stdin;
1	2	10	2026-10-01	234000	Total of Old & New Loan as on 01-10-2026	2026-10-20 09:57:51.70447
\.


--
-- Data for Name: employee_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_master (id, name, code, department_id, base_salary, overtime_rate_hr, att_allowance, oth_allowance, active, tenant_id) FROM stdin;
1	Umaid	001	2	1200.00	\N	2000.00	2000.00	t	1
4	Rasheed	003	2	1200.00	\N	2000.00	2000.00	f	1
5	Zain	005	2	1200.00	\N	2000.00	2000.00	f	1
7	Raza	007	2	1200.00	\N	2000.00	2000.00	t	1
9	Kareem	009	2	1200.00	\N	2000.00	2000.00	t	1
14	Safdar	9905	3	30000.00	100.00	3000.00	\N	t	1
16	Sardar	9907	3	30000.00	100.00	3000.00	\N	t	1
15	Dilshad	9906	3	30000.00	100.00	3000.00	\N	t	1
13	Zulfiqar	9904	4	33000.00	\N	2000.00	\N	f	1
18	Quality 	011	2	\N	\N	\N	\N	t	1
10	Iftikhar	9901	1	60000.00	\N	\N	\N	t	1
12	Liaquat	9903	1	85000.00	\N	\N	\N	t	1
17	Shiraj	9908	4	33000.00	\N	2000.00	\N	f	1
19	Muhammad Moosa	9909	4	33000.00	110.00	2000.00	\N	f	1
3	Sajiid Rehman	004	2	1200.00	\N	2000.00	2000.00	f	1
11	Imran	9902	1	38000.00	\N	\N	\N	t	1
30	Iqbal Ahmed 	012	2	1200.00	\N	\N	\N	t	1
8	Gul Muhammad	008	2	1200.00	\N	2000.00	2000.00	f	1
2	Nasir	002	2	1200.00	\N	2000.00	2000.00	f	1
20	Asif 	010	2	1200.00	0.00	2000.00	0.00	t	1
47	Alam	013	2	1200.00	0.00	2000.00	0.00	t	1
6	Rashid	006	2	1200.00	\N	2000.00	2000.00	f	1
46	Rashid 	014	2	1200.00	0.00	2000.00	0.00	t	1
48	Rabi	9910	4	35000.00	0.00	0.00	0.00	t	1
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
2	2026-10-13	Compressor	Air Filter - Services	submitted	Hassan Imam	2026-10-13 07:11:52.004154	\N	2026-10-13 07:11:52.004154	1
3	2026-10-13	Compressor	Fan Checking	submitted	Hassan Imam	2026-10-13 07:11:57.897662	\N	2026-10-13 07:11:57.897662	1
4	2026-10-13	Compressor	Oil Change	submitted	Hassan Imam	2026-10-13 07:12:09.093667	\N	2026-10-13 07:12:09.093667	1
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
258	2026-08-31	1	15	posted	4636080DIH5J7LP183631	00	"{\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"invoiceNumber\\": \\"4636080DIH5J7LP183631\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"dated\\": \\"2026-08-31 16:24:52\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"sourceInvoiceNo\\":\\"\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"validationResponse\\": {\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"error\\":\\"\\",\\"invoiceStatuses\\":[{\\"itemSNo\\":\\"1\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIH5J7LP183631-1\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"}]}\\n\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t}"	77113.75	13880.48	90994.23	Hassan Imam	2026-08-31 10:13:36.672554	2026-08-31 11:25:17.454	2026-08-31 11:25:17.454	90	fbr	1
256	2026-08-29	1	14	posted	4636080DIHBO9QS236084	00	"{\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"invoiceNumber\\": \\"4636080DIHBO9QS236084\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"dated\\": \\"2026-08-31 19:16:56\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"sourceInvoiceNo\\":\\"\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"validationResponse\\": {\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"error\\":\\"\\",\\"invoiceStatuses\\":[{\\"itemSNo\\":\\"1\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIHBO9QS236084-1\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"},{\\"itemSNo\\":\\"2\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIHBO9QS236084-2\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"}]}\\n\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t}"	590888.00	106359.84	697247.84	Khurram Hassan	2026-08-29 11:15:55.368811	2026-08-31 14:17:11.093	2026-08-31 14:17:11.093	60	fbr	1
257	2026-08-31	1	13	posted	4636080DIH5M9DJ827313	00	"{\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"invoiceNumber\\": \\"4636080DIH5M9DJ827313\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"dated\\": \\"2026-08-31 16:25:31\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"sourceInvoiceNo\\":\\"\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"validationResponse\\": {\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"error\\":\\"\\",\\"invoiceStatuses\\":[{\\"itemSNo\\":\\"1\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIH5M9DJ827313-1\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"}]}\\n\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t}"	257412.80	46334.30	303747.10	Hassan Imam	2026-08-31 10:08:13.198539	2026-08-31 11:27:39.672	2026-08-31 11:27:39.672	90	fbr	1
263	2026-08-31	1	17	posted	4636080DIHBKM7L351305	00	"{\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"invoiceNumber\\": \\"4636080DIHBKM7L351305\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"dated\\": \\"2026-08-31 19:12:12\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"sourceInvoiceNo\\":\\"\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"validationResponse\\": {\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"error\\":\\"\\",\\"invoiceStatuses\\":[{\\"itemSNo\\":\\"1\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIHBKM7L351305-1\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"},{\\"itemSNo\\":\\"2\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIHBKM7L351305-2\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"},{\\"itemSNo\\":\\"3\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIHBKM7L351305-3\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"}]}\\n\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t}"	102962.45	18533.25	121495.70	Tahir Hassan	2026-08-31 13:07:12.048544	2026-08-31 14:14:20.674	2026-08-31 14:14:20.674	60	fbr	1
259	2026-08-31	1	16	posted	4636080DIHBOGV4531979	00	"{\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"invoiceNumber\\": \\"4636080DIHBOGV4531979\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"dated\\": \\"2026-08-31 19:16:55\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"sourceInvoiceNo\\":\\"\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"validationResponse\\": {\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"error\\":\\"\\",\\"invoiceStatuses\\":[{\\"itemSNo\\":\\"1\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIHBOGV4531979-1\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"},{\\"itemSNo\\":\\"2\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIHBOGV4531979-2\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"},{\\"itemSNo\\":\\"3\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIHBOGV4531979-3\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"},{\\"itemSNo\\":\\"4\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIHBOGV4531979-4\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"},{\\"itemSNo\\":\\"5\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIHBOGV4531979-5\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"}]}\\n\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t}"	550228.30	99041.09	649269.39	Hassan Imam	2026-08-31 11:09:32.045096	2026-08-31 14:17:20.344	2026-08-31 14:17:20.344	90	fbr	1
264	2026-08-31	1	15	posted	4636080DIJ2N8L5953618	00	"{\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"invoiceNumber\\": \\"4636080DIJ2N8L5953618\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"dated\\": \\"2026-09-02 00:39:32\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"sourceInvoiceNo\\":\\"\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"validationResponse\\": {\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"error\\":\\"\\",\\"invoiceStatuses\\":[{\\"itemSNo\\":\\"1\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIJ2N8L5953618-1\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"}]}\\n\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t}"	23406.25	4213.13	27619.38	Hassan Imam	2026-09-01 07:55:31.562814	2026-09-01 19:39:58.812	2026-09-01 19:39:58.812	90	fbr	1
270	2026-09-30	1	16	posted	4636080DIOFKLX2422857	00	"{\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"invoiceNumber\\": \\"4636080DIOFKLX2422857\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"dated\\": \\"2026-09-30 23:17:37\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"sourceInvoiceNo\\":\\"\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"validationResponse\\": {\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"error\\":\\"\\",\\"invoiceStatuses\\":[{\\"itemSNo\\":\\"1\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIOFKLX2422857-1\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"}]}\\n\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t}"	9283.70	1671.07	10954.77	Khurram Hassan	2026-09-30 18:19:21.800858	2026-09-30 18:20:24.549	2026-09-30 18:20:24.549	90	fbr	1
269	2026-09-30	1	16	posted	4636080DIO07BPH273276	00	"{\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"invoiceNumber\\": \\"4636080DIO07BPH273276\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"dated\\": \\"2026-09-30 16:10:04\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"sourceInvoiceNo\\":\\"\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"validationResponse\\": {\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"error\\":\\"\\",\\"invoiceStatuses\\":[{\\"itemSNo\\":\\"1\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIO07BPH273276-1\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"},{\\"itemSNo\\":\\"2\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIO07BPH273276-2\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"},{\\"itemSNo\\":\\"3\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIO07BPH273276-3\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"}]}\\n\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t}"	718369.80	129306.56	847676.36	Hassan Imam	2026-09-30 11:04:18.24805	2026-09-30 11:10:10.493	2026-09-30 11:10:10.493	90	fbr	1
268	2026-09-30	1	17	posted	4636080DIO07E49002613	00	"{\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"invoiceNumber\\": \\"4636080DIO07E49002613\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"dated\\": \\"2026-09-30 16:07:27\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"sourceInvoiceNo\\":\\"\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"validationResponse\\": {\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"error\\":\\"\\",\\"invoiceStatuses\\":[{\\"itemSNo\\":\\"1\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIO07E49002613-1\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"},{\\"itemSNo\\":\\"2\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIO07E49002613-2\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"}]}\\n\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t}"	89491.00	16108.38	105599.38	Hassan Imam	2026-09-30 10:39:09.668803	2026-09-30 11:10:13.437	2026-09-30 11:10:13.437	60	fbr	1
267	2026-09-30	1	15	posted	4636080DIO07FM1851337	00	"{\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"invoiceNumber\\": \\"4636080DIO07FM1851337\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"dated\\": \\"2026-09-30 16:07:28\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"sourceInvoiceNo\\":\\"\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"validationResponse\\": {\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"error\\":\\"\\",\\"invoiceStatuses\\":[{\\"itemSNo\\":\\"1\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIO07FM1851337-1\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"}]}\\n\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t}"	36711.50	6608.07	43319.57	Hassan Imam	2026-09-30 10:12:19.33967	2026-09-30 11:10:15.369	2026-09-30 11:10:15.369	90	fbr	1
266	2026-09-30	1	13	posted	4636080DIO07GYQ123016	00	"{\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"invoiceNumber\\": \\"4636080DIO07GYQ123016\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"dated\\": \\"2026-09-30 16:10:11\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"sourceInvoiceNo\\":\\"\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"validationResponse\\": {\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"error\\":\\"\\",\\"invoiceStatuses\\":[{\\"itemSNo\\":\\"1\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIO07GYQ123016-1\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"}]}\\n\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t}"	232787.20	41901.70	274688.90	Hassan Imam	2026-09-30 10:10:00.987716	2026-09-30 11:10:17.145	2026-09-30 11:10:17.145	90	fbr	1
265	2026-09-30	1	14	posted	4636080DIO0I891886788	00	"{\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"invoiceNumber\\": \\"4636080DIO0I891886788\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"dated\\": \\"2026-09-30 16:17:52\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"sourceInvoiceNo\\":\\"\\",\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t\\"validationResponse\\": {\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"error\\":\\"\\",\\"invoiceStatuses\\":[{\\"itemSNo\\":\\"1\\",\\"statusCode\\":\\"00\\",\\"status\\":\\"Valid\\",\\"invoiceNo\\":\\"4636080DIO0I891886788-1\\",\\"errorCode\\":\\"\\",\\"error\\":\\"\\"}]}\\n\\n\\t\\t\\t\\t\\t\\t\\t\\t\\t\\t}"	687737.60	123792.77	811530.37	Hassan Imam	2026-09-30 10:01:57.250692	2026-09-30 11:18:39.057	2026-09-30 11:18:39.057	60	fbr	1
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
65	257	20	23	6002.9000	KG	3-Fleece fabric	8044.150	32.00	257412.80	46334.30	303747.10	Goods at standard rate (default)	1
66	258	20	23	6002.9000	KG	3-Fleece fabric	2203.250	35.00	77113.75	13880.48	90994.23	Goods at standard rate (default)	1
63	256	20	28	6002.9000	KG	3-Fleece fabric	6525.200	32.00	208806.40	37585.15	246391.55	Processing/Conversion of Goods	1
64	256	20	42	6002.9000	KG	3-Fleece fabric	11940.050	32.00	382081.60	68774.69	450856.29	Processing/Conversion of Goods	1
67	259	22	13	6002.9000	KG	Single Jersey fabric	873.700	20.00	17474.00	3145.32	20619.32	Processing/Conversion of Goods	1
68	259	24	39	6002.9000	KG	RIB (1X1) fabric	1668.050	80.00	133444.00	24019.92	157463.92	Processing/Conversion of Goods	1
69	259	20	26	6002.9000	KG	3-Fleece fabric	2604.600	34.00	88556.40	15940.15	104496.55	Processing/Conversion of Goods	1
70	259	20	23	6002.9000	KG	3-Fleece fabric	6631.350	34.00	225465.90	40583.86	266049.76	Processing/Conversion of Goods	1
71	259	23	39	6002.9000	KG	RIB (2X1) fabric	1066.100	80.00	85288.00	15351.84	100639.84	Processing/Conversion of Goods	1
81	263	20	26	6002.9000	KG	3-Fleece fabric	439.850	35.00	15394.75	2771.06	18165.81	Processing/Conversion of Goods	1
82	263	20	31	6002.9000	KG	3-Fleece fabric	2489.650	28.00	69710.20	12547.84	82258.04	Processing/Conversion of Goods	1
83	263	23	37	6002.9000	KG	RIB (2X1) fabric	595.250	30.00	17857.50	3214.35	21071.85	Processing/Conversion of Goods	1
84	264	20	23	6002.9000	KG	3-Fleece fabric	668.750	35.00	23406.25	4213.13	27619.38	Goods at standard rate (default)	1
85	265	20	49	6002.9000	KG	3-Fleece fabric	21491.800	32.00	687737.60	123792.77	811530.37	Goods at standard rate (default)	1
86	266	20	23	6002.9000	KG	3-Fleece fabric	7274.600	32.00	232787.20	41901.70	274688.90	Goods at standard rate (default)	1
87	267	20	23	6002.9000	KG	3-Fleece fabric	1048.900	35.00	36711.50	6608.07	43319.57	Goods at standard rate (default)	1
88	268	20	31	6002.9000	KG	3-Fleece fabric	2466.250	28.00	69055.00	12429.90	81484.90	Goods at standard rate (default)	1
89	268	23	37	6002.9000	KG	RIB (2X1) fabric	681.200	30.00	20436.00	3678.48	24114.48	Goods at standard rate (default)	1
90	269	20	23	6002.9000	KG	3-Fleece fabric	15025.700	34.00	510873.80	91957.28	602831.08	Goods at standard rate (default)	1
91	269	23	39	6002.9000	KG	RIB (2X1) fabric	2429.750	80.00	194380.00	34988.40	229368.40	Goods at standard rate (default)	1
92	269	22	13	6002.9000	KG	Single Jersey fabric	655.800	20.00	13116.00	2360.88	15476.88	Goods at standard rate (default)	1
93	270	20	23	6002.9000	KG	3-Fleece fabric	273.050	34.00	9283.70	1671.07	10954.77	Goods at standard rate (default)	1
\.


--
-- Data for Name: invoice_payment; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoice_payment (id, invoice_id, amount, tax_deduction, payment_date, method, reference, notes, paid_by, created_at, tenant_id) FROM stdin;
1	200	70241.00	0.00	2026-05-22	Cheque	CA-86523688	Soneri Bank	tahirhassan	2026-08-16 19:48:42.403862	1
2	229	583941.40	5839.41	2026-08-20	Cheque	87053434	Bank Al Habib Limited	tahirhassan	2026-08-20 09:31:44.514823	1
3	237	1076208.26	10762.08	2026-08-20	Cheque	87053564	Bank Al Habib Limited	tahirhassan	2026-08-20 09:32:24.514265	1
4	226	505908.19	5059.08	2026-08-24	Cheque	Chq#4210478-B-AL-H  Dt. 21-08-2026 	\N	hassanimam	2026-08-25 09:35:14.842191	1
7	243	477888.32	4778.88	2026-09-08	Bank Transfer	Chq#87053964 Dt. 20-07-2026  BANK AL-HABIB	\N	hassanimam	2026-09-08 07:28:04.939312	1
8	200	558581.06	5585.81	2026-09-08	Bank Transfer	Chq#CA-88358109-SONERI BANK Dt.12-09-2026	\N	hassanimam	2026-09-08 07:54:28.289319	1
9	217	3400.17	34.00	2026-09-08	Bank Transfer	Chq#CA-88358109-SONERI BANK Dt.12-09-2026	\N	hassanimam	2026-09-08 07:54:42.941975	1
10	233	9688.72	96.89	2026-09-08	Bank Transfer	Chq#CA-88358109-SONERI BANK Dt.12-09-2026	\N	hassanimam	2026-09-08 07:57:15.516301	1
11	227	184269.57	1842.70	2026-09-08	Bank Transfer	Eastern Online Transfer Payment received on 20-09-2026	\N	hassanimam	2026-09-08 07:59:36.872415	1
12	234	381867.68	3818.68	2026-09-16	Bank Transfer	4211012	Bank-Al-Habib LDT	khurramhassan	2026-09-16 08:48:42.507829	1
14	254	12282.53	153.53	2026-10-03	Bank Transfer	\N	\N	khurramhassan	2026-10-03 08:02:29.231451	1
16	236	140573.52	1757.17	2026-10-03	Bank Transfer	\N	\N	khurramhassan	2026-10-03 12:25:27.773186	1
17	235	787.06	7.87	2026-10-03	Bank Transfer	\N	\N	khurramhassan	2026-10-03 12:26:37.586132	1
18	234	1.09	0.01	2026-10-03	Bank Transfer	\N	\N	khurramhassan	2026-10-03 12:27:01.342168	1
19	254	1.03	0.01	2026-10-03	Bank Transfer	\N	\N	khurramhassan	2026-10-03 12:27:29.588195	1
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
13	257	161	1
14	257	162	1
15	257	170	1
16	257	175	1
17	257	177	1
18	257	178	1
19	257	180	1
20	257	190	1
21	257	209	1
22	257	296	1
23	258	163	1
24	258	294	1
25	259	172	1
26	259	199	1
27	259	215	1
28	259	216	1
29	259	217	1
30	259	219	1
31	259	220	1
32	259	233	1
33	259	234	1
34	259	235	1
35	259	246	1
36	259	247	1
37	259	248	1
38	259	249	1
39	259	260	1
40	259	261	1
41	259	262	1
42	259	263	1
43	259	266	1
44	259	267	1
45	259	268	1
46	259	273	1
47	259	295	1
54	263	173	1
55	263	272	1
56	264	298	1
57	265	362	1
58	265	367	1
59	265	377	1
60	265	376	1
61	265	384	1
62	265	387	1
63	265	397	1
64	265	400	1
65	265	405	1
66	265	411	1
67	266	304	1
68	266	303	1
69	266	318	1
70	266	320	1
71	266	324	1
72	266	334	1
73	266	344	1
74	267	330	1
75	268	319	1
76	268	345	1
77	269	302	1
78	269	317	1
79	269	333	1
80	269	349	1
81	269	368	1
82	269	383	1
83	269	402	1
84	269	414	1
85	269	416	1
86	269	419	1
87	270	420	1
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
25	Outtaq Private	Outtaq Private	23	1
26	Arif Slik	Arif Slik	21	1
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
13	24	M-010	M#10	3.75	2026-09-22	Sigma	2026-07-31	Kohala	updated	tahirhassan	2026-09-23 07:03:32.421299	1
14	23	M-009	M#09	3.75	2026-10-25	Sigma	2026-06-12	Kohala	updated	tahirhassan	2026-10-17 10:21:00.380681	1
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
8	2026-10-12	22	پلّی کی چابی (Key) کٹ گئی تھی، جس کی وجہ سے مشین میں مسئلہ پیدا ہو گیا تھا۔ اس خرابی کو دور کرنے کے لیے پلّی کی چابی کی مرمت کروائی گئی اور مشین کو درست حالت میں لانے کا کام مکمل کیا گیا۔	2000.000	Mohammed Ayub	submitted	Iftikhar Ahmed	2026-10-13 08:45:26.964803	Khurram Hassan	2026-10-13 10:20:49.498	1
9	2026-10-15	29	کمپریسر نمبر 2 کی مرمت کی رپورٹ\nکمپریسر نمبر 2 کی مرمت کا کام کروایا گیا۔ مرمت کے سلسلے میں درج ذیل کام کیے گئے:\nکمپریسر کی سروس اور مرمت کا کام کروایا گیا۔\nمختلف پرزوں کی مرمت اور ضروری کام انجام دیے گئے۔\nمرمت کے اخراجات کی تفصیل درج ذیل ہے:\nموٹر سروس + وائنڈنگ: 1500 روپے\nبیرنگ SKP 6205: 850 روپے\nبیرنگ SKP 6206: 1200 روپے\nکرینک کی گسکیٹ: 2500 روپے\nدیگر مرمتی کام: 350 روپے\nکل اخراجات: 6400 روپے	6400.000	Jaffar	submitted	Iftikhar Ahmed	2026-10-15 09:05:08.703731	\N	2026-10-15 09:05:08.703731	1
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
25	M#01	M-001	3.75	2025-12-24	Sigma	2025-12-24	Kohala	1
18	M#04	M-004	3.75	2026-08-19	Sigma	2026-08-19	Kohala	1
29	M#00	M-000	0.00	2026-08-01	Sigma	2026-08-01	Kohala	1
24	M#10	M-010	3.75	2026-09-22	Sigma	2026-07-31	Kohala	1
23	M#09	M-009	3.75	2026-10-25	Sigma	2026-06-12	Kohala	1
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
22	TKT Textiles	TKT	1.00	4636080	Sindh	Shade#1-A, Plot No.L-39/1, Block-22, F. B Industrial Area, Karachi, Central Gulberg Town	Registered	30	1
23	Outtak Apparel	Outtak	1.00	\N	\N	\N	Unregistered	90	1
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
1	receipt	net_weight	1008.000000	1304.735000	960.724800	0.000000	4922.205000	139	2026-10-26 16:34:35.853	1
2	receipt	quantity	25.000000	29.000000	22.239000	0.000000	112.000000	139	2026-10-26 16:34:35.86	1
3	receipt	wt_per_bag	45.360000	9.360000	0.196307	17.280000	73.440000	139	2026-10-26 16:34:35.868	1
4	receipt	net_total@receipt:party	2268.000000	3557.922500	2674.417662	0.000000	12941.767500	20	2026-10-26 16:34:35.875	1
5	receipt	net_total@receipt:count	1360.800000	1884.440000	1430.412480	0.000000	7014.120000	33	2026-10-26 16:34:35.88	1
6	receipt	net_total@receipt:party+count	1360.800000	1640.770000	1345.014720	0.000000	6283.110000	39	2026-10-26 16:34:35.889	1
7	receipt	net_total@receipt:party+brand	726.000000	2926.190000	862.873200	0.000000	9504.570000	33	2026-10-26 16:34:35.895	1
8	receipt	net_total@receipt:count+brand	1111.320000	1632.395000	1143.173556	0.000000	6008.505000	40	2026-10-26 16:34:35.899	1
9	receipt	net_total@receipt:date+party	2268.000000	3557.922500	2674.417662	0.000000	12941.767500	20	2026-10-26 16:34:35.904	1
65	production	roll_weight	27.450000	4.500000	3.113460	13.950000	40.950000	5788	2026-10-26 09:13:31.033	1
66	production	total_weight	194.900000	86.800000	53.818380	0.000000	455.300000	373	2026-10-26 09:13:31.048	1
67	production	total_weight@date	2272.225000	894.500000	694.635165	0.000000	4955.725000	30	2026-10-26 09:13:31.093	1
10	receipt	net_total@receipt:date+party+count	1360.800000	1640.770000	1345.014720	0.000000	6283.110000	39	2026-10-26 16:34:35.909	1
68	production	total_weight@shift	1158.525000	544.300000	406.417725	0.000000	2791.425000	60	2026-10-26 09:13:31.106	1
69	production	total_weight@machine	385.725000	176.187500	100.631475	0.000000	914.287500	190	2026-10-26 09:13:31.12	1
70	production	total_weight@employee	547.050000	251.100000	189.550410	0.000000	1300.350000	119	2026-10-26 09:13:31.147	1
71	production	total_weight@date+shift	1158.525000	544.300000	406.417725	0.000000	2791.425000	60	2026-10-26 09:13:31.187	1
72	production	total_weight@date+machine	385.725000	176.187500	100.631475	0.000000	914.287500	190	2026-10-26 09:13:31.198	1
21	delivery	net_weight	694.750000	996.450000	734.183520	0.000000	3684.100000	209	2026-10-26 12:54:57.534	1
22	delivery	quantity	25.000000	38.000000	25.204200	0.000000	139.000000	209	2026-10-26 12:54:57.541	1
23	delivery	gsm	250.000000	8.750000	7.413000	223.750000	276.250000	30	2026-10-26 12:54:57.545	1
24	delivery	wt_per_roll	26.440000	3.473363	2.326094	16.019912	36.860088	209	2026-10-26 12:54:57.551	1
25	delivery	net_total@delivery:party	1412.800000	1793.800000	1160.431020	0.000000	6794.200000	35	2026-10-26 12:54:57.558	1
26	delivery	net_total@delivery:type	1410.150000	2128.450000	1587.419820	0.000000	7795.500000	39	2026-10-26 12:54:57.564	1
27	delivery	net_total@delivery:party+type	1401.550000	1497.900000	1317.660750	0.000000	5895.250000	47	2026-10-26 12:54:57.573	1
28	delivery	net_total@delivery:party+gsm_band	1412.800000	1793.800000	1160.431020	0.000000	6794.200000	35	2026-10-26 12:54:57.58	1
29	delivery	net_total@delivery:type+gsm_band	1410.150000	2128.450000	1587.419820	0.000000	7795.500000	39	2026-10-26 12:54:57.587	1
30	delivery	net_total@delivery:date+party	1412.800000	1793.800000	1160.431020	0.000000	6794.200000	35	2026-10-26 12:54:57.592	1
31	delivery	net_total@delivery:date+party+type	1401.550000	1497.900000	1317.660750	0.000000	5895.250000	47	2026-10-26 12:54:57.595	1
73	production	total_weight@date+employee	547.050000	251.100000	189.550410	0.000000	1300.350000	119	2026-10-26 09:13:31.208	1
74	production	total_weight@shift+machine	197.300000	78.187500	50.704920	0.000000	431.862500	362	2026-10-26 09:13:31.221	1
75	production	total_weight@shift+employee	538.475000	262.337500	213.272010	0.000000	1325.487500	122	2026-10-26 09:13:31.232	1
76	production	total_weight@machine+employee	197.250000	74.525000	49.074060	0.000000	420.825000	363	2026-10-26 09:13:31.251	1
77	production	total_weight@machine+party	381.050000	199.900000	109.119360	0.000000	980.750000	197	2026-10-26 09:13:31.296	1
78	production	total_weight@date+shift+machine	197.300000	78.187500	50.704920	0.000000	431.862500	362	2026-10-26 09:13:31.311	1
79	production	total_weight@date+shift+employee	538.475000	262.337500	213.272010	0.000000	1325.487500	122	2026-10-26 09:13:31.319	1
80	production	total_weight@date+machine+employee	197.250000	74.525000	49.074060	0.000000	420.825000	363	2026-10-26 09:13:31.332	1
81	production	total_weight@date+machine+party	381.050000	199.900000	109.119360	0.000000	980.750000	197	2026-10-26 09:13:31.343	1
82	production	total_weight@date+employee+party	249.500000	259.450000	197.704710	0.000000	1027.850000	219	2026-10-26 09:13:31.385	1
83	production	total_weight@shift+machine+employee	197.200000	77.487500	49.630035	0.000000	429.662500	364	2026-10-26 09:13:31.395	1
84	production	total_weight@shift+machine+party	196.350000	85.600000	53.373600	0.000000	453.150000	369	2026-10-26 09:13:31.424	1
85	production	total_weight@shift+employee+party	239.950000	260.900000	209.639640	0.000000	1022.650000	221	2026-10-26 09:13:31.445	1
86	production	total_weight@machine+employee+party	196.600000	82.850000	50.408400	0.000000	445.150000	370	2026-10-26 09:13:31.497	1
87	production	total_weight@date+shift+machine+employee	197.200000	77.487500	49.630035	0.000000	429.662500	364	2026-10-26 09:13:31.51	1
88	production	total_weight@date+shift+machine+party	196.350000	85.600000	53.373600	0.000000	453.150000	369	2026-10-26 09:13:31.522	1
89	production	total_weight@date+shift+employee+party	239.950000	260.900000	209.639640	0.000000	1022.650000	221	2026-10-26 09:13:31.537	1
90	production	total_weight@date+machine+employee+party	196.600000	82.850000	50.408400	0.000000	445.150000	370	2026-10-26 09:13:31.549	1
91	production	total_weight@shift+machine+employee+party	196.350000	84.400000	51.594480	0.000000	449.550000	371	2026-10-26 09:13:31.6	1
92	production	total_weight@date+shift+machine+employee+party	196.350000	84.400000	51.594480	0.000000	449.550000	371	2026-10-26 09:13:31.618	1
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
42	production	roll_weight	16.800000	17.400000	37.500000	confirmed_anyway	Iftikhar Ahmed	2026-08-30 06:33:10.250067	1
43	production	roll_weight	15.150000	17.400000	37.500000	confirmed_anyway	Iftikhar Ahmed	2026-08-30 06:33:10.250067	1
44	production	roll_weight	12.150000	17.400000	37.500000	confirmed_anyway	Iftikhar Ahmed	2026-08-30 06:34:09.271318	1
45	production	roll_weight	16.450000	17.400000	37.500000	confirmed_anyway	Iftikhar Ahmed	2026-08-30 06:36:16.302703	1
46	production	roll_weight	16.650000	17.400000	37.500000	confirmed_anyway	Iftikhar Ahmed	2026-09-01 04:45:42.782854	1
47	production	roll_weight	13.450000	17.400000	37.500000	confirmed_anyway	Iftikhar Ahmed	2026-09-01 04:46:34.620309	1
48	production	roll_weight	13.750000	17.350000	37.450000	confirmed_anyway	Iftikhar Ahmed	2026-09-01 04:49:05.662828	1
49	receipt	net_weight	4536.000000	0.000000	4258.260000	confirmed_anyway	Iftikhar Ahmed	2026-09-01 06:26:25.532894	1
50	receipt	quantity	100.000000	0.000000	77.000000	confirmed_anyway	Iftikhar Ahmed	2026-09-01 06:26:25.532894	1
51	receipt	net_weight	4536.000000	0.000000	4327.695000	confirmed_anyway	Iftikhar Ahmed	2026-09-01 06:27:14.251711	1
52	receipt	quantity	100.000000	0.000000	78.000000	confirmed_anyway	Iftikhar Ahmed	2026-09-01 06:27:14.251711	1
53	production	roll_weight	12.250000	17.000000	37.700000	confirmed_anyway	Iftikhar Ahmed	2026-09-03 15:29:21.985097	1
54	production	roll_weight	16.250000	16.850000	37.850000	confirmed_anyway	Iftikhar Ahmed	2026-09-04 05:16:48.437551	1
55	production	roll_weight	13.550000	16.850000	37.850000	confirmed_anyway	Iftikhar Ahmed	2026-09-05 05:53:24.136969	1
56	production	roll_weight	13.850000	16.850000	37.850000	confirmed_anyway	Iftikhar Ahmed	2026-09-05 05:56:29.317669	1
57	production	roll_weight	8.100000	16.850000	37.850000	confirmed_anyway	Iftikhar Ahmed	2026-09-05 05:56:29.317669	1
58	production	roll_weight	13.300000	16.700000	38.000000	confirmed_anyway	Iftikhar Ahmed	2026-09-06 06:51:54.944212	1
59	production	roll_weight	15.900000	16.663000	38.038000	confirmed_anyway	Iftikhar Ahmed	2026-09-06 06:55:28.431545	1
60	production	roll_weight	14.400000	16.350000	38.250000	confirmed_anyway	Iftikhar Ahmed	2026-09-07 05:58:24.506116	1
61	production	roll_weight	11.500000	16.500000	38.100000	confirmed_anyway	Iftikhar Ahmed	2026-09-08 05:44:52.70711	1
62	production	roll_weight	14.400000	16.425000	38.175000	confirmed_anyway	Iftikhar Ahmed	2026-09-09 09:10:47.889018	1
63	production	roll_weight	14.600000	16.463000	38.138000	confirmed_anyway	Iftikhar Ahmed	2026-09-09 09:12:23.507344	1
64	production	roll_weight	15.100000	16.463000	38.138000	confirmed_anyway	Iftikhar Ahmed	2026-09-09 09:12:23.507344	1
65	delivery	gsm	330.000000	235.000000	265.000000	confirmed_anyway	Iftikhar Ahmed	2026-09-09 10:06:23.350861	1
66	production	roll_weight	16.200000	16.238000	38.363000	confirmed_anyway	Iftikhar Ahmed	2026-09-10 05:02:08.236075	1
67	production	roll_weight	16.300000	16.350000	38.250000	confirmed_anyway	Iftikhar Ahmed	2026-09-10 05:04:55.957951	1
68	production	roll_weight	13.900000	16.300000	38.200000	confirmed_anyway	Iftikhar Ahmed	2026-09-13 06:25:52.758768	1
69	production	roll_weight	14.450000	16.100000	38.300000	confirmed_anyway	Iftikhar Ahmed	2026-09-14 05:35:36.439174	1
70	production	roll_weight	14.500000	16.300000	38.200000	confirmed_anyway	Iftikhar Ahmed	2026-09-17 05:31:09.734719	1
71	production	roll_weight	15.250000	16.200000	38.400000	confirmed_anyway	Iftikhar Ahmed	2026-09-22 05:14:54.179859	1
72	production	roll_weight	15.200000	16.200000	38.400000	confirmed_anyway	Iftikhar Ahmed	2026-09-22 05:14:54.179859	1
73	production	roll_weight	14.650000	16.050000	38.550000	confirmed_anyway	Iftikhar Ahmed	2026-09-24 05:22:20.55668	1
74	production	roll_weight	0.500000	16.050000	38.550000	confirmed_anyway	Khurram Hassan	2026-09-24 07:17:58.386666	1
75	production	roll_weight	15.650000	16.013000	38.588000	confirmed_anyway	Iftikhar Ahmed	2026-09-25 05:17:12.492825	1
76	production	roll_weight	0.500000	16.050000	38.550000	confirmed_anyway	Khurram Hassan	2026-09-25 07:25:17.69863	1
77	production	roll_weight	0.500000	16.050000	38.550000	confirmed_anyway	Khurram Hassan	2026-09-25 07:42:25.231801	1
78	production	roll_weight	10.650000	16.000000	38.500000	confirmed_anyway	Iftikhar Ahmed	2026-09-27 10:31:21.179033	1
79	production	roll_weight	14.150000	15.850000	38.650000	confirmed_anyway	Iftikhar Ahmed	2026-09-28 08:05:24.292821	1
80	production	roll_weight	14.000000	15.850000	38.650000	confirmed_anyway	Iftikhar Ahmed	2026-09-28 08:05:24.292821	1
81	production	roll_weight	14.650000	15.700000	38.800000	confirmed_anyway	Iftikhar Ahmed	2026-09-28 08:06:17.738652	1
82	receipt	net_weight	4808.160000	0.000000	4764.150000	confirmed_anyway	Iftikhar Ahmed	2026-09-28 13:01:06.032366	1
83	receipt	quantity	106.000000	0.000000	103.000000	confirmed_anyway	Iftikhar Ahmed	2026-09-28 13:01:06.032366	1
84	production	roll_weight	15.550000	15.750000	38.850000	confirmed_anyway	Iftikhar Ahmed	2026-10-04 06:30:03.33001	1
85	production	roll_weight	15.200000	15.600000	39.000000	confirmed_anyway	Iftikhar Ahmed	2026-10-04 06:31:47.536078	1
86	production	roll_weight	12.800000	15.600000	39.000000	confirmed_anyway	Iftikhar Ahmed	2026-10-05 05:53:29.018195	1
87	receipt	net_weight	5125.680000	0.000000	4764.150000	confirmed_anyway	Iftikhar Ahmed	2026-10-06 14:41:10.931392	1
88	receipt	quantity	113.000000	0.000000	103.000000	confirmed_anyway	Iftikhar Ahmed	2026-10-06 14:41:10.931392	1
89	production	roll_weight	13.400000	15.450000	39.150000	confirmed_anyway	Iftikhar Ahmed	2026-10-08 05:35:23.299129	1
90	production	roll_weight	15.100000	15.450000	39.150000	confirmed_anyway	Iftikhar Ahmed	2026-10-09 05:25:07.97779	1
91	production	roll_weight	14.900000	15.450000	39.150000	confirmed_anyway	Iftikhar Ahmed	2026-10-09 05:34:50.903144	1
92	production	roll_weight	14.500000	15.450000	39.150000	confirmed_anyway	Iftikhar Ahmed	2026-10-09 05:36:15.287324	1
93	production	roll_weight	14.900000	15.300000	39.300000	confirmed_anyway	Iftikhar Ahmed	2026-10-10 05:41:48.360827	1
94	production	roll_weight	14.700000	15.300000	39.300000	confirmed_anyway	Iftikhar Ahmed	2026-10-10 05:44:12.04821	1
95	production	roll_weight	7.000000	15.150000	39.450000	confirmed_anyway	Iftikhar Ahmed	2026-10-11 08:08:32.128723	1
96	production	roll_weight	14.600000	15.150000	39.450000	confirmed_anyway	Iftikhar Ahmed	2026-10-11 08:09:17.884075	1
97	production	roll_weight	8.600000	15.000000	39.600000	confirmed_anyway	Iftikhar Ahmed	2026-10-12 05:47:52.417079	1
98	production	roll_weight	8.350000	15.000000	39.600000	confirmed_anyway	Iftikhar Ahmed	2026-10-12 05:47:52.417079	1
99	production	roll_weight	12.700000	15.000000	39.600000	confirmed_anyway	Iftikhar Ahmed	2026-10-12 05:47:52.417079	1
100	production	roll_weight	12.200000	15.000000	39.600000	confirmed_anyway	Iftikhar Ahmed	2026-10-13 05:51:49.104831	1
101	production	roll_weight	13.250000	15.000000	39.600000	confirmed_anyway	Iftikhar Ahmed	2026-10-13 05:52:29.707995	1
102	production	roll_weight	8.650000	15.000000	39.600000	confirmed_anyway	Iftikhar Ahmed	2026-10-13 05:53:30.394225	1
103	production	roll_weight	12.100000	14.875000	39.775000	confirmed_anyway	Iftikhar Ahmed	2026-10-14 06:09:03.184057	1
104	production	roll_weight	14.050000	14.850000	39.750000	confirmed_anyway	Iftikhar Ahmed	2026-10-14 06:10:31.492964	1
105	production	roll_weight	10.800000	14.850000	39.750000	confirmed_anyway	Iftikhar Ahmed	2026-10-14 06:11:30.075557	1
106	delivery	wt_per_roll	10.800000	16.445000	36.467000	confirmed_anyway	Iftikhar Ahmed	2026-10-16 06:01:37.0237	1
107	production	roll_weight	10.700000	14.600000	40.100000	confirmed_anyway	Iftikhar Ahmed	2026-10-17 05:26:09.250231	1
108	production	roll_weight	14.250000	14.600000	40.100000	confirmed_anyway	Iftikhar Ahmed	2026-10-17 05:26:50.179845	1
109	production	roll_weight	14.450000	14.600000	40.100000	confirmed_anyway	Khurram Hassan	2026-10-19 07:27:51.29546	1
110	production	roll_weight	12.550000	14.650000	40.150000	confirmed_anyway	Khurram Hassan	2026-10-19 07:33:42.19513	1
111	production	roll_weight	13.100000	14.600000	40.100000	confirmed_anyway	Khurram Hassan	2026-10-19 07:50:28.624479	1
112	production	roll_weight	11.900000	14.488000	40.213000	confirmed_anyway	Khurram Hassan	2026-10-19 07:54:43.093144	1
113	production	roll_weight	10.900000	14.450000	40.250000	confirmed_anyway	Iftikhar Ahmed	2026-10-20 06:40:07.28771	1
114	production	roll_weight	12.400000	14.300000	40.400000	confirmed_anyway	Iftikhar Ahmed	2026-10-20 06:41:53.323099	1
115	production	roll_weight	12.550000	14.025000	40.725000	confirmed_anyway	Iftikhar Ahmed	2026-10-22 06:15:14.673008	1
116	production	roll_weight	7.000000	14.000000	40.700000	confirmed_anyway	Iftikhar Ahmed	2026-10-23 05:21:52.295466	1
117	production	roll_weight	13.750000	14.000000	40.700000	confirmed_anyway	Iftikhar Ahmed	2026-10-23 05:22:41.397772	1
118	receipt	wt_per_bag	8.000000	17.280000	73.440000	confirmed_anyway	Iftikhar Ahmed	2026-10-23 12:33:21.168983	1
119	production	roll_weight	8.350000	14.050000	40.750000	confirmed_anyway	Iftikhar Ahmed	2026-10-24 05:30:26.646075	1
120	production	roll_weight	12.950000	13.950000	40.950000	confirmed_anyway	Iftikhar Ahmed	2026-10-26 09:10:42.094855	1
121	receipt	wt_per_bag	16.633000	17.280000	73.440000	confirmed_anyway	Iftikhar Ahmed	2026-10-26 14:36:51.785038	1
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
52	4	15	8	2026	3	Dilshad	30000.00	100.00	3000.00	0.00	31.0	0.0	0.0	31.0	33200.00	32.00	3200.00	26000.00	0.00	0.00	10200.00	1
53	4	8	8	2026	2	Gul Muhammad	1200.00	0.00	2000.00	2000.00	29.0	2.0	0.0	29.0	43266.77	0.00	0.00	23000.00	0.00	0.00	20266.77	1
54	4	10	8	2026	1	Iftikhar	55000.00	0.00	0.00	0.00	31.0	0.0	0.0	31.0	55000.00	0.00	0.00	24000.00	0.00	0.00	31000.00	1
55	4	11	8	2026	1	Imran	36000.00	0.00	0.00	0.00	31.0	0.0	0.0	31.0	36000.00	0.00	0.00	15000.00	0.00	0.00	21000.00	1
56	4	9	8	2026	2	Kareem	1200.00	0.00	2000.00	2000.00	31.0	0.0	0.0	31.0	55808.70	0.00	0.00	20000.00	0.00	0.00	37808.70	1
57	4	12	8	2026	1	Liaquat	80000.00	0.00	0.00	0.00	31.0	0.0	0.0	31.0	80000.00	0.00	0.00	36000.00	0.00	0.00	44000.00	1
58	4	19	8	2026	4	Muhammad Moosa	33000.00	110.00	2000.00	0.00	6.0	25.0	0.0	6.0	6387.10	0.00	0.00	0.00	0.00	0.00	6387.10	1
59	4	2	8	2026	2	Nasir	1200.00	0.00	2000.00	2000.00	30.0	1.0	0.0	30.0	48840.27	0.00	0.00	20000.00	0.00	0.00	28840.27	1
60	4	18	8	2026	2	Quality 	0.00	0.00	0.00	0.00	8.0	23.0	0.0	8.0	0.00	0.00	0.00	0.00	0.00	0.00	0.00	1
61	4	7	8	2026	2	Raza	1200.00	0.00	2000.00	2000.00	31.0	0.0	0.0	31.0	39819.75	0.00	0.00	15000.00	0.00	0.00	26819.75	1
62	4	14	8	2026	3	Safdar	30000.00	100.00	3000.00	0.00	30.0	1.0	0.0	30.0	30932.26	19.00	1900.00	24000.00	0.00	0.00	6932.26	1
63	4	3	8	2026	2	Sajiid Rehman	1200.00	0.00	2000.00	2000.00	1.0	30.0	0.0	1.0	1533.00	0.00	0.00	0.00	0.00	0.00	1533.00	1
64	4	16	8	2026	3	Sardar	30000.00	100.00	3000.00	0.00	27.0	4.0	0.0	27.0	26929.03	8.00	800.00	23000.00	0.00	0.00	3929.03	1
65	4	17	8	2026	4	Shiraj	33000.00	0.00	2000.00	0.00	2.0	29.0	0.0	2.0	2129.03	0.00	0.00	0.00	0.00	0.00	2129.03	1
66	4	1	8	2026	2	Umaid	1200.00	0.00	2000.00	2000.00	31.0	0.0	0.0	31.0	42312.75	0.00	0.00	14000.00	0.00	0.00	30312.75	1
67	5	20	9	2026	2	Asif 	1200.00	0.00	2000.00	0.00	4.0	26.0	0.0	4.0	8984.52	0.00	0.00	3000.00	0.00	0.00	5984.52	1
68	5	15	9	2026	3	Dilshad	30000.00	100.00	3000.00	0.00	30.0	0.0	0.0	30.0	31900.00	19.00	1900.00	22000.00	0.00	0.00	12900.00	1
69	5	8	9	2026	2	Gul Muhammad	1200.00	0.00	2000.00	2000.00	20.0	10.0	0.0	20.0	31190.63	0.00	0.00	31190.00	0.00	0.00	0.63	1
70	5	10	9	2026	1	Iftikhar	60000.00	0.00	0.00	0.00	30.0	0.0	0.0	30.0	60000.00	0.00	0.00	39500.00	0.00	0.00	20500.00	1
71	5	11	9	2026	1	Imran	38000.00	0.00	0.00	0.00	30.0	0.0	0.0	30.0	38000.00	0.00	0.00	10000.00	0.00	0.00	28000.00	1
72	5	30	9	2026	2	Iqbal Ahmed 	1200.00	0.00	0.00	0.00	1.0	29.0	0.0	1.0	1269.00	0.00	0.00	0.00	0.00	0.00	1269.00	1
73	5	9	9	2026	2	Kareem	1200.00	0.00	2000.00	2000.00	30.0	0.0	0.0	30.0	60347.48	0.00	0.00	25000.00	0.00	0.00	37347.48	1
74	5	12	9	2026	1	Liaquat	85000.00	0.00	0.00	0.00	30.0	0.0	0.0	30.0	85000.00	0.00	0.00	35000.00	0.00	0.00	50000.00	1
75	5	2	9	2026	2	Nasir	1200.00	0.00	2000.00	2000.00	16.0	14.0	0.0	16.0	26339.63	0.00	0.00	22000.00	0.00	0.00	4339.63	1
76	5	18	9	2026	2	Quality 	0.00	0.00	0.00	0.00	2.0	28.0	0.0	2.0	0.00	0.00	0.00	0.00	0.00	0.00	0.00	1
77	5	7	9	2026	2	Raza	1200.00	0.00	2000.00	2000.00	30.0	0.0	0.0	30.0	46582.42	0.00	0.00	10000.00	0.00	0.00	38582.42	1
78	5	14	9	2026	3	Safdar	30000.00	100.00	3000.00	0.00	30.0	0.0	0.0	30.0	30800.00	8.00	800.00	17500.00	0.00	0.00	16300.00	1
79	5	16	9	2026	3	Sardar	30000.00	100.00	3000.00	0.00	30.0	0.0	0.0	30.0	31400.00	14.00	1400.00	21000.00	0.00	0.00	13400.00	1
80	5	1	9	2026	2	Umaid	1200.00	0.00	2000.00	2000.00	21.0	9.0	0.0	21.0	33456.22	0.00	0.00	21500.00	0.00	0.00	11956.22	1
\.


--
-- Data for Name: salary_header; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.salary_header (id, month, year, department_ids, posted, created_at, updated_at, tenant_id) FROM stdin;
4	8	2026	{1,4,3,2}	t	2026-09-04 13:22:57.838124	2026-09-05 11:39:41.714	1
5	9	2026	{1,4,3,2}	t	2026-10-03 10:29:53.072362	2026-10-03 11:05:34.095	1
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
994	330	38.000	1048.900	\N	\N	20	23	1	1	1
502	154	5.000	149.250	23	7	20	23	1	1	1
503	154	8.000	198.600	23	2	20	23	1	1	1
504	154	5.000	130.050	24	1	20	23	1	1	1
1001	334	47.000	1209.550	\N	\N	20	23	20	1	1
1257	406	7.000	193.600	25	9	20	49	1	1	1
505	154	7.000	194.700	24	9	20	23	1	1	1
1258	406	1.000	16.000	25	1	20	49	1	1	1
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
1259	406	8.000	214.250	14	9	20	49	1	1	1
1260	406	7.000	173.050	15	20	20	49	1	1	1
1261	406	5.000	145.900	18	20	20	49	1	1	1
1262	406	7.000	191.850	24	9	20	49	1	1	1
1263	406	7.000	183.650	24	1	20	49	1	1	1
1290	406	2.000	53.900	14	20	20	49	1	1	1
1303	416	26.000	701.200	\N	\N	20	23	24	1	1
547	166	6.000	153.900	23	7	20	23	1	1	1
548	166	8.000	206.900	23	2	20	23	1	1	1
549	166	5.000	135.550	24	1	20	23	1	1	1
550	166	6.000	175.450	24	9	20	23	1	1	1
596	146	6.000	171.500	24	9	20	23	2	1	1
829	261	10.000	249.600	\N	\N	23	39	3	1	1
835	267	10.000	251.800	\N	\N	23	39	3	1	1
1304	416	4.000	114.800	\N	\N	23	39	3	1	1
1305	416	26.000	699.400	\N	\N	20	23	24	1	1
1306	416	4.000	117.950	\N	\N	23	39	24	1	1
1307	416	26.000	707.500	\N	\N	20	23	24	1	1
883	292	8.000	224.450	25	1	20	23	2	1	1
884	292	7.000	195.300	25	9	20	23	2	1	1
885	292	7.000	205.050	14	8	20	23	2	1	1
886	292	5.000	128.700	14	2	20	23	2	1	1
1308	416	5.000	115.750	\N	\N	23	39	3	1	1
963	319	30.000	858.250	\N	\N	20	31	23	1	1
580	176	50.000	1422.800	\N	\N	20	28	1	1	1
581	176	59.000	1663.250	\N	\N	20	28	1	1	1
583	178	25.000	672.600	\N	\N	20	23	2	1	1
586	180	25.000	671.800	\N	\N	20	23	2	1	1
893	295	30.000	804.350	\N	\N	20	23	1	1	1
894	295	5.000	119.500	\N	\N	23	39	3	1	1
895	295	30.000	810.050	\N	\N	20	23	1	1	1
896	295	5.000	117.800	\N	\N	23	39	3	1	1
897	295	17.000	415.550	\N	\N	22	13	3	1	1
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
713	215	60.000	1564.400	\N	\N	20	26	3	1	1
715	217	10.000	270.650	\N	\N	20	26	3	1	1
902	298	24.000	668.750	\N	\N	20	23	2	1	1
910	301	7.000	186.700	22	8	20	23	20	1	1
911	301	6.000	146.450	22	9	20	23	20	1	1
912	301	7.000	177.100	23	7	20	23	20	1	1
654	139	6.000	161.050	22	8	20	23	2	1	1
655	139	5.000	153.250	22	9	20	23	2	1	1
656	139	7.000	167.900	23	7	20	23	2	1	1
657	139	8.000	194.200	23	2	20	23	2	1	1
661	197	7.000	143.500	22	7	20	23	2	1	1
662	197	3.000	91.500	22	2	20	23	2	1	1
663	197	4.000	108.200	24	1	20	23	2	1	1
913	301	8.000	217.300	23	9	20	23	20	1	1
914	301	8.000	197.350	24	1	20	23	20	1	1
915	301	7.000	178.300	24	9	20	23	20	1	1
919	304	33.000	815.600	\N	\N	20	23	20	1	1
568	170	20.000	498.150	\N	\N	20	23	2	1	1
726	224	49.000	1388.750	\N	\N	20	42	1	1	1
727	224	51.000	1429.200	\N	\N	20	42	1	1	1
867	285	1.000	3.350	29	18	20	23	13	1	1
673	201	1.000	694.750	29	18	20	23	2	1	1
484	150	6.000	171.050	25	1	20	28	1	1	1
485	150	7.000	194.200	25	9	20	28	1	1	1
486	150	9.000	252.800	14	8	20	28	1	1	1
487	150	8.000	266.050	14	9	20	28	1	1	1
488	150	7.000	210.150	15	8	20	28	1	1	1
489	150	9.000	275.650	15	2	20	28	1	1	1
698	209	47.000	1137.500	\N	\N	20	23	2	1	1
1452	445	4.000	98.400	25	1	20	26	24	1	1
1453	445	8.000	216.500	25	9	20	26	24	1	1
1454	445	3.000	84.700	14	1	20	26	24	1	1
1455	445	7.000	188.450	15	7	20	26	24	1	1
1456	445	7.000	206.950	15	46	20	26	24	1	1
1457	445	7.000	177.650	18	7	20	26	24	1	1
869	287	1.000	25.350	29	18	20	23	2	1	1
1458	445	7.000	208.650	18	46	20	26	24	1	1
859	280	1.000	10.750	29	18	24	39	3	1	1
519	158	100.000	4536.000	\N	\N	24	13	3	1	1
887	293	4.000	101.700	29	18	20	23	20	1	1
888	293	6.000	150.700	23	7	20	23	20	1	1
889	293	9.000	225.500	23	2	20	23	20	1	1
526	162	47.000	1233.900	\N	\N	20	23	2	1	1
528	132	6.000	162.300	25	1	20	29	1	1	1
529	132	7.000	206.400	25	3	20	29	1	1	1
530	132	3.000	88.300	14	8	20	29	1	1	1
531	132	9.000	251.200	14	9	20	29	1	1	1
532	132	6.000	156.150	15	8	20	29	1	1	1
533	132	4.000	116.150	15	2	20	29	1	1	1
538	140	6.000	148.450	24	1	20	23	1	1	1
539	140	7.000	202.400	24	3	20	23	1	1	1
890	293	5.000	136.400	24	1	20	23	20	1	1
891	293	2.000	53.100	24	9	20	23	20	1	1
898	296	42.000	1035.200	\N	\N	20	23	2	1	1
718	219	5.000	117.000	\N	\N	24	39	3	1	1
903	299	1.000	24.300	22	8	20	23	20	1	1
904	299	2.000	55.300	22	2	20	23	20	1	1
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
905	299	8.000	186.050	23	7	20	23	20	1	1
906	299	8.000	198.800	23	2	20	23	20	1	1
907	299	7.000	171.500	24	1	20	23	20	1	1
908	299	7.000	179.650	24	9	20	23	20	1	1
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
525	161	27.000	694.750	\N	\N	20	23	2	1	1
590	147	6.000	145.850	23	7	20	23	2	1	1
1309	417	9.000	408.240	\N	\N	20	2	20	1	1
591	147	8.000	212.750	23	2	20	23	2	1	1
692	208	8.000	224.000	25	1	20	42	1	1	1
693	208	7.000	183.200	25	9	20	42	1	1	1
694	208	9.000	276.350	14	8	20	42	1	1	1
695	208	5.000	137.650	14	9	20	42	1	1	1
696	208	9.000	265.450	15	8	20	42	1	1	1
697	208	8.000	229.950	15	2	20	42	1	1	1
711	214	7.000	204.900	15	8	20	42	1	1	1
712	214	7.000	192.550	15	2	20	42	1	1	1
964	319	10.000	225.250	\N	\N	23	37	23	1	1
1002	335	3.000	88.800	\N	\N	20	2	24	1	1
806	251	7.000	154.000	21	8	23	39	3	1	1
807	251	7.000	170.550	21	9	23	39	3	1	1
872	289	3.000	79.650	25	1	20	23	14	1	1
873	289	9.000	259.500	25	9	20	23	14	1	1
965	319	31.000	867.250	\N	\N	20	31	23	1	1
966	319	11.000	218.300	\N	\N	23	37	23	1	1
879	291	4.000	73.850	23	7	20	23	20	1	1
880	291	6.000	149.100	23	2	20	31	20	1	1
881	291	4.000	88.550	24	1	20	23	20	1	1
882	291	6.000	158.000	24	9	20	23	20	1	1
1023	341	5.000	149.050	15	8	20	23	23	1	1
1024	341	2.000	56.150	15	2	20	23	23	1	1
1143	375	9.000	324.000	\N	\N	20	20	18	1	1
1144	375	36.000	1562.160	\N	\N	20	2	18	1	1
1145	375	37.000	1642.050	\N	\N	20	53	18	1	1
1170	382	9.000	324.000	\N	\N	20	20	18	1	1
1171	382	35.000	1562.160	\N	\N	20	2	1	1	1
1040	347	1.000	24.050	15	7	20	26	1	1	1
1172	382	37.000	1642.050	\N	\N	20	53	1	1	1
1215	395	9.000	324.000	\N	\N	20	20	18	1	1
1216	395	35.000	1562.160	\N	\N	20	2	1	1	1
1217	395	37.000	1642.050	\N	\N	20	53	1	1	1
567	169	127.000	5760.720	\N	\N	20	1	1	1	1
1310	418	1.000	34.000	\N	\N	20	2	1	1	1
1311	418	1.000	13.850	\N	\N	20	53	1	1	1
716	218	56.000	1549.050	\N	\N	20	42	1	1	1
717	218	50.000	1377.550	\N	\N	20	42	1	1	1
1312	418	18.000	648.000	\N	\N	20	20	18	1	1
1313	418	10.000	308.800	\N	\N	20	20	18	1	1
1197	390	6.000	135.200	21	1	23	39	3	1	1
1053	350	8.000	218.300	25	7	20	23	1	1	1
1054	350	9.000	239.950	25	9	20	23	1	1	1
1055	350	8.000	229.600	14	8	20	23	1	1	1
1056	350	9.000	228.100	14	2	20	23	1	1	1
1057	350	10.000	243.350	18	8	20	23	1	1	1
1058	350	9.000	243.300	18	2	20	23	1	1	1
1059	350	5.000	121.600	21	7	23	39	3	1	1
1060	350	2.000	39.550	21	9	23	39	3	1	1
995	331	12.000	432.000	\N	\N	20	19	18	1	1
851	275	11.000	498.960	\N	\N	\N	2	1	1	1
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
481	148	1.000	15.100	18	7	20	26	1	1	1
756	229	8.000	167.100	21	1	23	39	3	1	1
757	229	7.000	160.800	21	9	23	39	3	1	1
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
870	288	15.000	680.400	\N	\N	20	1	1	1	1
800	248	19.000	506.750	\N	\N	20	23	3	1	1
827	259	5.000	133.700	21	9	23	13	15	1	1
802	250	8.000	217.600	25	1	20	23	1	1	1
803	250	9.000	236.850	25	9	20	23	1	1	1
804	250	8.000	212.800	14	1	20	23	1	1	1
805	250	8.000	199.300	14	2	20	23	1	1	1
871	288	33.000	1496.880	\N	\N	20	2	1	1	1
951	313	20.000	453.600	\N	\N	20	1	1	1	1
808	252	8.000	202.800	15	7	20	31	3	1	1
809	252	9.000	236.700	18	7	20	31	3	1	1
810	252	9.000	258.500	18	2	20	31	3	1	1
811	253	2.000	40.000	\N	\N	23	22	18	1	1
812	254	1.000	14.720	\N	\N	23	22	18	1	1
670	199	6.000	150.600	\N	\N	24	39	3	1	1
1003	336	5.000	226.800	\N	\N	20	13	15	1	1
1004	336	32.000	1451.520	\N	\N	20	2	15	1	1
714	216	26.000	718.900	\N	\N	24	39	3	1	1
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
854	278	2.000	42.200	25	1	20	23	3	1	1
855	278	4.000	114.550	25	9	20	23	3	1	1
856	278	2.000	44.100	14	8	20	23	3	1	1
857	278	8.000	225.550	14	2	20	23	3	1	1
878	290	28.000	1270.080	\N	\N	20	1	20	1	1
801	249	3.000	72.900	\N	\N	23	39	3	1	1
892	294	45.000	1212.800	\N	\N	20	23	2	1	1
828	260	15.000	425.850	\N	\N	22	13	3	1	1
862	283	7.000	194.600	25	1	20	23	3	1	1
863	283	9.000	235.100	25	2	20	23	3	1	1
864	283	7.000	198.500	14	1	20	23	3	1	1
865	283	5.000	235.550	14	2	20	23	3	1	1
860	281	1.000	91.600	29	18	20	26	2	1	1
866	284	1.000	8.450	29	18	20	23	1	1	1
858	279	1.000	5.800	29	18	23	39	3	1	1
684	206	1.000	372.450	29	18	20	23	1	1	1
685	207	1.000	183.500	29	18	20	32	3	1	1
899	297	25.000	1134.000	\N	\N	20	2	2	1	1
900	297	12.000	432.000	\N	\N	20	19	18	1	1
901	297	28.000	1270.080	\N	\N	20	1	20	1	1
909	300	100.000	4536.000	\N	\N	20	1	15	1	1
916	302	30.000	800.400	\N	\N	20	23	1	1	1
917	302	5.000	120.400	\N	\N	23	39	3	1	1
918	303	47.000	1204.900	\N	\N	20	23	20	1	1
850	274	2.000	82.300	\N	\N	23	13	3	1	1
920	305	30.000	1080.000	\N	\N	20	19	18	1	1
921	305	28.000	1008.000	\N	\N	20	19	18	1	1
972	322	4.000	89.150	21	9	23	39	23	1	1
973	323	7.000	206.400	22	8	20	23	20	1	1
974	323	6.000	166.250	22	9	20	23	20	1	1
975	323	6.000	154.050	23	7	20	23	20	1	1
976	323	7.000	166.350	24	1	20	23	20	1	1
977	323	4.000	110.050	24	9	20	23	20	1	1
853	277	3.000	66.800	19	7	22	13	3	1	1
978	324	17.000	430.450	\N	\N	20	23	20	1	1
984	326	6.000	165.100	24	1	20	23	20	1	1
985	326	7.000	163.600	24	2	20	23	20	1	1
986	327	8.000	203.950	22	7	20	23	23	1	1
987	327	3.000	79.000	22	2	20	23	23	1	1
988	327	8.000	191.350	23	7	20	23	23	1	1
989	327	7.000	182.300	23	2	20	23	23	1	1
990	327	5.000	125.300	24	9	20	23	23	1	1
991	327	7.000	181.750	24	8	20	23	23	1	1
992	328	75.000	3402.000	\N	\N	20	1	4	1	1
646	193	1.000	309.350	29	18	24	39	3	1	1
647	193	1.000	1809.200	29	18	20	26	3	1	1
648	193	1.000	17.900	29	18	22	13	3	1	1
761	230	9.000	231.550	14	2	20	23	3	1	1
762	230	5.000	123.300	15	8	20	23	3	1	1
763	230	7.000	189.000	18	7	20	23	3	1	1
764	230	7.000	206.950	18	2	20	23	3	1	1
933	308	6.000	198.000	\N	\N	20	19	18	1	1
934	309	3.000	113.380	\N	\N	23	13	3	1	1
1300	413	1.000	0.500	29	18	\N	\N	\N	\N	1
1239	401	60.000	2721.600	\N	\N	20	2	24	1	1
1459	445	8.000	144.750	19	7	22	13	3	1	1
1460	445	7.000	148.150	22	7	20	26	24	1	1
672	200	8.000	176.450	\N	\N	22	2	1	1	1
1325	422	7.000	178.150	15	9	20	23	24	1	1
1326	422	8.000	218.050	15	7	20	23	24	1	1
1327	422	8.000	237.100	18	9	20	23	24	1	1
1461	445	5.000	153.000	22	46	20	26	24	1	1
1494	457	3.000	95.940	\N	\N	20	2	15	1	1
1513	462	60.000	1720.400	\N	\N	20	28	1	1	1
1514	462	2.000	48.550	\N	\N	20	28	1	1	1
1521	465	97.000	4381.190	\N	\N	20	1	1	1	1
1522	466	8.000	232.900	14	1	20	28	1	1	1
1523	466	8.000	240.950	14	46	20	28	1	1	1
1524	466	5.000	132.650	15	7	20	28	1	1	1
935	310	5.000	138.950	25	1	20	23	1	1	1
936	310	9.000	246.100	25	9	20	23	1	1	1
937	310	4.000	124.050	14	8	20	23	1	1	1
938	310	9.000	246.350	14	9	20	23	1	1	1
945	312	10.000	297.550	15	8	20	31	21	1	1
946	312	9.000	238.250	15	2	20	31	21	1	1
947	312	10.000	289.300	18	7	20	31	21	1	1
948	312	9.000	251.950	18	2	20	31	21	1	1
949	312	6.000	112.150	21	1	23	39	21	1	1
950	312	7.000	151.350	21	9	23	39	21	1	1
928	307	1.000	20.250	15	8	20	31	21	1	1
929	307	8.000	230.750	15	2	20	31	21	1	1
930	307	1.000	22.800	18	7	20	31	21	1	1
931	307	8.000	227.800	18	2	20	31	21	1	1
932	307	7.000	157.900	21	9	23	39	21	1	1
922	306	7.000	189.000	22	8	20	23	20	1	1
923	306	8.000	209.700	22	9	20	23	20	1	1
924	306	7.000	177.900	23	7	20	23	20	1	1
925	306	6.000	153.200	23	2	20	23	20	1	1
926	306	7.000	178.150	24	1	20	23	20	1	1
927	306	7.000	181.850	24	9	20	23	20	1	1
939	311	8.000	225.250	22	8	20	23	20	1	1
940	311	8.000	201.050	22	9	20	23	20	1	1
941	311	8.000	181.450	23	7	20	23	20	1	1
942	311	7.000	173.650	23	2	20	23	20	1	1
943	311	8.000	194.400	24	1	20	23	20	1	1
944	311	7.000	192.350	24	9	20	23	20	1	1
952	314	30.000	1080.000	\N	\N	20	19	18	1	1
953	315	25.000	1134.000	\N	\N	20	2	23	1	1
954	315	10.000	360.000	\N	\N	20	19	18	1	1
955	315	28.000	1270.080	\N	\N	20	1	20	1	1
956	316	42.000	1905.120	\N	\N	20	13	23	1	1
962	318	42.000	1089.800	\N	\N	20	23	20	1	1
750	228	9.000	243.150	25	1	20	23	1	1	1
751	228	9.000	236.800	25	9	20	23	1	1	1
752	228	9.000	231.800	14	8	20	23	1	1	1
753	228	9.000	234.850	14	2	20	23	1	1	1
754	228	8.000	195.050	18	7	20	26	1	1	1
755	228	6.000	176.200	18	2	20	26	1	1	1
570	172	1.000	5.300	\N	\N	22	13	3	1	1
571	172	1.000	9.500	\N	\N	24	39	3	1	1
572	172	19.000	561.250	\N	\N	24	39	3	1	1
573	172	14.000	401.700	\N	\N	20	26	13	1	1
574	172	1.000	11.800	\N	\N	22	13	3	1	1
575	172	4.000	100.050	\N	\N	24	39	3	1	1
462	143	5.000	119.150	18	7	20	26	3	1	1
463	143	5.000	127.000	18	2	20	26	3	1	1
464	143	7.000	192.450	21	1	23	39	3	1	1
465	143	8.000	218.350	21	9	23	39	3	1	1
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
742	227	8.000	228.800	25	1	20	23	3	1	1
743	227	9.000	244.000	25	9	20	23	3	1	1
744	227	8.000	220.800	14	8	20	23	3	1	1
745	227	9.000	236.800	14	2	20	23	3	1	1
746	227	7.000	160.800	18	7	20	23	3	1	1
747	227	7.000	206.750	18	2	20	23	3	1	1
748	227	6.000	149.400	21	1	23	39	3	1	1
749	227	7.000	160.600	21	9	23	39	3	1	1
847	273	15.000	367.850	\N	\N	20	26	3	1	1
848	273	28.000	733.000	\N	\N	20	23	3	1	1
849	273	8.000	162.550	\N	\N	23	39	3	1	1
799	247	2.000	49.850	\N	\N	23	39	3	1	1
719	220	1.000	5.200	\N	\N	22	13	3	1	1
720	220	1.000	24.800	\N	\N	20	23	3	1	1
967	320	46.000	1168.150	\N	\N	20	23	20	1	1
968	321	8.000	208.700	25	1	20	23	1	1	1
969	322	9.000	266.400	15	8	20	31	23	1	1
970	322	7.000	207.350	15	9	20	31	23	1	1
971	322	9.000	171.150	21	1	23	39	23	1	1
980	326	7.000	184.050	22	8	20	23	20	1	1
981	326	8.000	219.200	22	9	20	23	20	1	1
982	326	7.000	177.200	23	7	20	23	20	1	1
983	326	8.000	206.500	23	9	20	23	20	1	1
645	182	1.000	5951.360	\N	\N	20	26	1	1	1
993	329	1.000	39.800	29	18	20	23	1	1	1
758	230	9.000	246.800	25	1	20	23	3	1	1
759	230	9.000	239.700	25	9	20	23	3	1	1
760	230	9.000	233.250	14	8	20	23	3	1	1
997	333	37.000	935.450	\N	\N	20	23	1	1	1
998	333	14.000	318.100	\N	\N	23	39	3	1	1
999	333	16.000	456.250	\N	\N	22	13	3	1	1
1000	333	10.000	227.850	\N	\N	23	39	3	1	1
540	136	4.000	102.700	18	7	20	26	3	1	1
541	136	1.000	23.800	18	2	20	26	3	1	1
542	136	8.000	199.350	21	1	24	39	3	1	1
543	136	7.000	209.700	21	9	24	39	3	1	1
957	317	38.000	998.100	\N	\N	20	23	1	1	1
958	317	7.000	145.850	\N	\N	23	39	3	1	1
959	317	60.000	1615.400	\N	\N	20	23	1	1	1
960	317	5.000	136.350	\N	\N	20	23	1	1	1
961	317	12.000	277.800	\N	\N	23	39	3	1	1
1014	340	8.000	233.000	25	8	20	23	1	1	1
1015	340	9.000	249.350	25	9	20	23	1	1	1
1016	340	8.000	226.750	14	8	20	23	1	1	1
1017	340	8.000	215.600	14	2	20	23	1	1	1
1018	340	5.000	127.600	18	7	20	23	1	1	1
1019	340	9.000	205.050	18	2	20	23	1	1	1
1020	340	1.000	14.400	19	7	22	13	3	1	1
1021	340	5.000	90.000	21	7	23	39	3	1	1
1022	340	8.000	172.150	21	9	23	39	3	1	1
1025	342	40.000	1814.400	\N	\N	20	2	15	1	1
1028	344	32.000	799.550	\N	\N	20	23	20	1	1
1029	344	20.000	556.600	\N	\N	20	23	20	1	1
1175	384	60.000	1616.900	\N	\N	20	49	1	1	1
1176	384	5.000	121.550	\N	\N	20	49	1	1	1
569	171	2.000	39.700	\N	\N	20	29	1	1	1
1328	422	8.000	220.700	18	7	20	23	24	1	1
1329	422	8.000	205.350	22	9	20	23	24	1	1
1041	348	2.000	90.720	\N	\N	1	2	1	1	1
1042	348	12.000	544.320	\N	\N	17	2	1	1	1
1043	348	3.000	136.080	\N	\N	15	2	13	1	1
1044	348	1.000	45.360	\N	\N	14	13	1	1	1
1045	348	1.000	45.360	\N	\N	14	1	1	1	1
1046	348	1.000	45.360	\N	\N	14	14	1	1	1
1061	351	89.000	4037.040	\N	\N	23	13	24	1	1
1330	422	8.000	191.200	22	1	20	23	24	1	1
1198	391	28.000	1008.000	\N	\N	20	20	18	1	1
1199	391	35.000	1562.170	\N	\N	20	2	1	1	1
1200	391	37.000	1642.060	\N	\N	20	53	1	1	1
1070	354	4.000	104.750	15	8	20	49	1	1	1
1071	354	9.000	217.150	15	2	20	49	1	1	1
1072	354	3.000	78.800	18	8	20	49	1	1	1
1073	354	9.000	216.450	18	2	20	49	1	1	1
1065	353	6.000	162.700	25	7	20	23	1	1	1
1066	353	9.000	253.600	25	9	20	23	1	1	1
1067	353	8.000	213.100	14	8	20	23	1	1	1
1068	353	10.000	262.750	14	9	20	23	1	1	1
1069	353	3.000	82.550	18	8	20	23	1	1	1
1074	355	70.000	3175.200	\N	\N	20	1	15	\N	1
1075	356	6.000	122.100	14	7	20	49	1	1	1
1076	356	7.000	181.800	14	9	20	49	1	1	1
1077	356	9.000	210.800	15	8	20	49	1	1	1
1078	356	8.000	212.800	15	2	20	49	1	1	1
1079	356	9.000	225.900	18	8	20	49	1	1	1
1080	356	8.000	220.850	18	2	20	49	1	1	1
1081	357	9.000	232.900	14	7	20	49	17	1	1
1082	357	8.000	220.400	14	2	20	49	17	1	1
1083	357	8.000	216.250	15	8	20	49	17	1	1
1084	357	8.000	219.000	15	9	20	49	17	1	1
1085	357	8.000	231.900	18	8	20	49	17	1	1
1086	357	8.000	231.150	18	9	20	49	17	1	1
1087	358	8.000	200.300	25	7	20	49	1	1	1
1088	358	8.000	216.850	25	9	20	49	1	1	1
1089	358	1.000	29.400	14	7	20	49	1	1	1
1090	358	4.000	89.550	22	7	20	49	1	1	1
1091	358	1.000	26.250	22	9	20	49	1	1	1
1092	359	9.000	239.350	25	7	20	49	1	1	1
1093	359	8.000	217.150	25	2	20	49	1	1	1
1094	359	8.000	181.700	22	7	20	49	1	1	1
1095	359	7.000	192.800	22	2	20	49	1	1	1
1096	360	1.000	24.050	\N	\N	20	26	\N	1	1
1285	410	1.000	19.950	25	9	20	49	1	1	1
1291	412	8.000	223.800	15	9	20	23	24	1	1
1292	412	4.000	105.200	15	1	20	23	24	1	1
1293	412	9.000	248.500	18	9	20	23	24	1	1
1294	412	8.000	223.100	18	7	20	23	24	1	1
1295	412	8.000	197.150	19	9	22	13	3	1	1
1104	364	3.000	136.080	\N	\N	20	2	1	1	1
1105	364	25.000	1134.080	\N	\N	20	2	1	1	1
1106	364	1.000	17.300	\N	\N	20	2	1	1	1
1296	412	6.000	141.750	19	7	22	13	3	1	1
1297	412	5.000	127.050	21	9	23	39	3	1	1
1298	412	8.000	209.200	22	9	20	23	24	1	1
1299	412	8.000	192.600	22	1	20	23	24	1	1
1009	338	4.000	102.250	23	7	20	23	3	1	1
1010	338	1.000	11.500	23	2	20	23	3	1	1
979	325	7.000	208.650	15	7	20	31	23	1	1
1005	337	1.000	18.500	25	8	20	23	1	1	1
1006	337	2.000	53.200	25	9	20	23	1	1	1
1007	337	9.000	233.050	14	9	20	23	1	1	1
1008	337	7.000	184.550	19	2	22	13	3	1	1
1012	337	1.000	0.400	29	18	20	23	1	1	1
1013	337	1.000	1.050	29	18	22	13	1	1	1
1107	365	7.000	194.150	14	7	20	49	1	1	1
1108	365	8.000	211.600	14	9	20	49	1	1	1
1109	365	8.000	216.450	15	8	20	49	1	1	1
1110	365	8.000	213.600	15	9	20	49	1	1	1
1111	365	8.000	228.850	18	8	20	49	1	1	1
1112	365	8.000	227.400	18	2	20	49	1	1	1
1026	343	2.000	90.720	\N	\N	20	2	25	1	1
1027	343	1.000	18.000	\N	\N	20	2	1	1	1
1097	361	3.000	97.100	\N	\N	20	2	4	1	1
1118	368	60.000	1548.100	\N	\N	20	23	1	1	1
1119	368	17.000	454.150	\N	\N	20	23	1	1	1
1120	368	14.000	303.950	\N	\N	23	39	3	1	1
1121	369	3.000	136.080	\N	\N	20	2	15	1	1
1116	367	60.000	1661.850	\N	\N	20	49	1	1	1
1117	367	3.000	83.700	\N	\N	20	49	1	1	1
1098	362	60.000	1476.450	\N	\N	20	49	1	1	1
1099	362	11.000	279.400	\N	\N	20	49	1	1	1
1100	362	22.000	609.450	\N	\N	20	49	1	1	1
1122	370	7.000	184.150	22	7	20	23	1	1	1
1123	370	6.000	175.250	22	2	20	23	1	1	1
1124	371	7.000	196.850	14	1	20	49	1	1	1
1125	371	6.000	168.250	14	9	20	49	1	1	1
1126	371	8.000	216.450	15	8	20	49	1	1	1
1127	371	6.000	162.350	15	9	20	49	1	1	1
1128	371	8.000	232.000	18	8	20	49	1	1	1
1129	371	6.000	174.000	18	2	20	49	1	1	1
1130	372	8.000	216.300	14	1	20	49	1	1	1
1131	372	6.000	167.350	14	9	20	49	1	1	1
1132	372	8.000	210.400	15	8	20	49	1	1	1
1133	372	6.000	170.450	15	2	20	49	1	1	1
1134	372	7.000	182.650	18	7	20	49	1	1	1
1135	372	6.000	175.100	18	2	20	49	1	1	1
1136	373	2.000	53.950	22	7	20	23	1	1	1
1316	420	10.000	273.050	\N	\N	20	23	24	1	1
1062	352	17.000	612.000	\N	\N	20	20	18	1	1
1063	352	41.000	1838.180	\N	\N	20	2	1	1	1
1064	352	42.000	1932.180	\N	\N	20	1	1	1	1
1146	376	60.000	1646.050	\N	\N	20	49	1	1	1
1147	376	4.000	95.350	\N	\N	20	49	1	1	1
1177	385	9.000	204.550	\N	\N	20	2	\N	1	1
1047	349	12.000	261.500	\N	\N	23	39	3	1	1
1048	349	18.000	495.500	\N	\N	20	23	1	1	1
1049	349	60.000	1597.750	\N	\N	20	23	1	1	1
1050	349	13.000	358.200	\N	\N	20	23	1	1	1
1051	349	18.000	458.250	\N	\N	20	23	1	1	1
1052	349	10.000	201.500	\N	\N	23	39	3	1	1
1032	346	8.000	227.650	25	8	20	23	1	1	1
1033	346	9.000	251.850	25	9	20	23	1	1	1
1034	346	8.000	223.100	14	8	20	23	1	1	1
1035	346	9.000	241.500	14	2	20	23	1	1	1
1036	346	9.000	223.150	18	7	20	23	1	1	1
1037	346	9.000	232.600	18	2	20	23	1	1	1
1038	346	7.000	157.600	21	7	23	39	3	1	1
1039	346	8.000	163.150	21	9	23	39	3	1	1
1137	374	7.000	194.350	14	1	20	49	1	1	1
1138	374	1.000	20.200	14	9	20	49	1	1	1
1139	374	7.000	197.700	15	8	20	49	1	1	1
1140	374	5.000	130.000	15	9	20	49	1	1	1
1141	374	6.000	169.800	18	7	20	49	1	1	1
1142	374	2.000	47.600	18	9	20	49	1	1	1
1148	377	60.000	1673.400	\N	\N	20	49	1	1	1
1149	377	3.000	72.550	\N	\N	20	49	1	1	1
686	204	5.000	130.100	18	7	20	26	1	1	1
687	204	5.000	142.000	18	2	20	26	1	1	1
688	204	4.000	116.650	19	7	22	13	1	1	1
689	204	7.000	211.250	19	2	22	13	1	1	1
690	204	2.000	33.650	21	1	24	39	1	1	1
691	204	3.000	83.350	21	9	24	39	1	1	1
1150	378	5.000	125.800	14	8	20	49	1	1	1
1151	378	7.000	197.100	14	9	20	49	1	1	1
1152	378	5.000	117.700	15	1	20	49	1	1	1
1153	378	8.000	203.550	15	2	20	49	1	1	1
1154	378	5.000	112.500	18	7	20	49	1	1	1
1155	378	8.000	216.600	18	2	20	49	1	1	1
1156	379	8.000	215.500	14	1	20	49	1	1	1
1157	379	8.000	207.600	14	2	20	49	1	1	1
1158	379	8.000	216.200	15	8	20	49	1	1	1
1159	379	8.000	222.500	15	9	20	49	1	1	1
1160	379	7.000	202.000	18	7	20	49	1	1	1
1161	379	8.000	227.950	18	9	20	49	1	1	1
1162	380	3.000	83.700	14	8	20	49	1	1	1
1163	380	13.000	355.350	14	1	20	49	1	1	1
1164	380	3.000	85.200	15	9	20	49	1	1	1
1165	380	12.000	336.850	15	1	20	49	1	1	1
1166	380	3.000	84.500	18	9	20	49	1	1	1
1167	380	12.000	341.700	18	7	20	49	1	1	1
1168	381	1.000	29.200	19	7	22	13	3	1	1
1169	381	1.000	31.050	21	1	23	39	3	1	1
1178	386	3.000	50.050	25	9	20	49	1	1	1
1179	386	6.000	165.500	25	1	20	49	1	1	1
1180	386	8.000	209.100	14	9	20	49	1	1	1
1181	386	7.000	195.400	14	1	20	49	1	1	1
1182	386	7.000	184.500	15	9	20	49	1	1	1
1183	386	7.000	196.500	15	7	20	49	1	1	1
1184	386	8.000	215.850	18	9	20	49	1	1	1
1185	386	7.000	194.900	18	7	20	49	1	1	1
1186	387	60.000	1661.100	\N	\N	20	49	1	1	1
1187	387	3.000	84.550	\N	\N	20	49	1	1	1
1113	366	3.000	66.850	25	7	20	49	1	1	1
1114	366	8.000	207.550	22	8	20	49	1	1	1
1188	388	8.000	206.050	22	2	20	23	1	1	1
1189	389	7.000	176.850	25	9	20	49	1	1	1
1190	389	7.000	196.950	25	1	20	49	1	1	1
1191	389	7.000	199.600	14	9	20	49	1	1	1
1192	389	8.000	223.400	14	1	20	49	1	1	1
1193	389	7.000	193.900	15	9	20	49	1	1	1
1194	389	8.000	219.550	15	7	20	49	1	1	1
1195	389	7.000	196.950	18	9	20	49	1	1	1
1196	389	8.000	217.950	18	7	20	49	1	1	1
1443	444	7.000	190.100	14	1	20	26	24	1	1
1444	444	7.000	191.000	14	9	20	26	24	1	1
1445	444	7.000	183.250	15	1	20	26	24	1	1
1301	414	8.000	199.550	\N	\N	22	13	3	1	1
1314	419	30.000	805.500	\N	\N	20	23	24	1	1
1315	419	6.000	143.350	\N	\N	23	39	3	1	1
1317	421	7.000	203.350	14	30	20	23	24	1	1
1318	421	9.000	266.200	14	1	20	23	24	1	1
1319	421	9.000	251.500	15	9	20	23	24	1	1
1320	421	9.000	249.300	15	7	20	23	24	1	1
1321	421	9.000	256.850	18	9	20	23	24	1	1
1322	421	9.000	251.150	18	7	20	23	24	1	1
1323	421	5.000	135.050	22	30	20	23	24	1	1
1446	444	7.000	212.200	15	46	20	26	24	1	1
1447	444	5.000	121.850	18	7	20	26	24	1	1
1448	444	8.000	222.900	18	46	20	26	24	1	1
1211	393	8.000	224.300	19	20	22	13	3	1	1
1212	393	6.000	142.600	21	9	23	39	3	1	1
1213	393	7.000	148.650	21	1	23	39	3	1	1
1449	444	8.000	174.250	19	7	22	13	3	1	1
1450	444	1.000	19.700	22	7	20	26	24	1	1
1451	444	6.000	131.850	22	9	20	26	24	1	1
1462	446	2.000	44.500	25	1	20	28	1	1	1
1218	396	1.000	7.250	\N	\N	20	1	\N	1	1
1219	396	3.000	65.850	\N	\N	20	19	18	1	1
1463	446	4.000	97.950	14	1	20	28	1	1	1
1220	397	60.000	1620.600	\N	\N	20	49	1	1	1
1221	397	5.000	122.050	\N	\N	20	49	1	1	1
1222	397	56.000	1523.100	\N	\N	20	49	1	1	1
1223	397	9.000	221.750	\N	\N	20	49	1	1	1
560	152	30.000	1360.800	\N	\N	20	1	1	1	1
561	152	17.000	612.000	\N	\N	20	41	18	1	1
562	152	29.000	1278.310	\N	\N	20	17	1	1	1
577	174	58.000	1721.300	\N	\N	20	28	1	1	1
578	174	59.000	1717.850	\N	\N	20	28	1	1	1
616	168	54.000	2442.290	\N	\N	20	1	1	1	1
617	168	33.000	1478.100	\N	\N	20	17	1	1	1
557	151	34.000	1542.240	\N	\N	20	1	1	1	1
558	151	12.000	432.000	\N	\N	20	41	18	1	1
559	151	50.000	2268.000	\N	\N	20	17	1	1	1
653	196	23.000	828.000	\N	\N	20	41	18	1	1
584	179	52.000	1514.900	\N	\N	20	42	1	1	1
585	179	52.000	1518.400	\N	\N	20	42	1	1	1
641	191	36.000	1011.850	\N	\N	20	42	1	1	1
642	191	49.000	1391.000	\N	\N	20	42	1	1	1
643	191	27.000	759.350	\N	\N	20	42	1	1	1
723	223	24.000	777.650	\N	\N	20	20	18	1	1
724	223	1.000	27.250	\N	\N	20	2	1	1	1
725	223	1.000	4.550	\N	\N	20	1	1	1	1
728	225	1.000	7.600	\N	\N	20	17	1	1	1
729	225	1.000	5.150	\N	\N	20	17	1	1	1
730	225	1.000	32.000	\N	\N	20	41	18	1	1
731	225	5.000	180.000	\N	\N	20	41	18	1	1
1173	383	56.000	1511.900	\N	\N	20	23	1	1	1
1174	383	4.000	80.950	\N	\N	23	39	3	1	1
1237	400	60.000	1634.800	\N	\N	20	49	1	1	1
1238	400	4.000	106.350	\N	\N	20	49	1	1	1
1201	392	7.000	174.850	25	9	20	49	1	1	1
1202	392	8.000	205.450	25	1	20	49	1	1	1
1203	392	8.000	207.650	14	9	20	49	1	1	1
1204	392	8.000	215.450	14	7	20	49	1	1	1
1205	392	8.000	212.800	15	20	20	49	1	1	1
1206	392	8.000	221.550	15	7	20	49	1	1	1
1207	392	8.000	217.650	18	20	20	49	1	1	1
1208	392	8.000	211.950	18	7	20	49	1	1	1
1209	392	4.000	102.750	24	9	20	49	1	1	1
1210	392	6.000	173.250	24	1	20	49	1	1	1
1224	398	7.000	196.250	25	9	20	49	1	1	1
1225	398	8.000	196.600	25	1	20	49	1	1	1
1226	398	8.000	214.900	14	9	20	49	1	1	1
1227	398	8.000	210.850	14	7	20	49	1	1	1
1228	398	8.000	213.700	15	20	20	49	1	1	1
1229	398	8.000	202.300	15	7	20	49	1	1	1
1230	398	8.000	219.150	18	20	20	49	1	1	1
1231	398	8.000	210.300	18	7	20	49	1	1	1
1232	398	6.000	169.650	24	9	20	49	1	1	1
1233	398	8.000	201.900	24	1	20	49	1	1	1
1240	402	46.000	1202.550	\N	\N	20	23	1	1	1
1241	403	7.000	178.950	25	9	20	49	1	1	1
1242	403	8.000	201.950	25	1	20	49	1	1	1
1243	403	7.000	189.700	14	9	20	49	1	1	1
1244	403	8.000	219.000	14	7	20	49	1	1	1
1245	403	7.000	190.450	15	20	20	49	1	1	1
1246	403	8.000	203.950	15	7	20	49	1	1	1
1247	403	7.000	203.750	18	20	20	49	1	1	1
1248	403	8.000	219.000	18	7	20	49	1	1	1
1249	403	6.000	179.500	24	9	20	49	1	1	1
1250	403	8.000	222.200	24	1	20	49	1	1	1
1251	404	2.000	48.150	19	20	22	13	23	1	1
1252	404	6.000	153.150	21	9	23	39	23	1	1
1253	404	7.000	163.950	21	1	23	39	23	1	1
1254	404	5.000	126.000	22	20	20	23	23	1	1
1264	407	2.000	48.350	18	20	20	23	24	1	1
1265	407	8.000	215.000	18	7	20	23	24	1	1
1266	407	7.000	152.850	19	20	22	13	3	1	1
1267	407	8.000	176.600	19	7	22	13	3	1	1
1268	407	6.000	152.400	21	9	23	39	3	1	1
1269	407	5.000	128.250	21	1	23	39	3	1	1
1270	407	7.000	178.850	22	20	20	23	24	1	1
1271	407	7.000	163.600	22	7	20	23	24	1	1
1272	408	6.000	174.850	25	1	20	49	1	1	1
1273	408	3.000	81.300	24	1	20	49	1	1	1
1302	415	106.000	4808.160	\N	\N	20	2	24	1	1
1464	446	8.000	241.250	14	9	20	28	1	1	1
1465	446	6.000	169.600	24	1	20	28	1	1	1
1466	446	8.000	241.700	24	9	20	28	1	1	1
1467	447	50.000	2268.000	\N	\N	20	2	15	1	1
1030	345	25.000	740.750	\N	\N	20	31	23	1	1
1031	345	12.000	237.650	\N	\N	23	37	23	1	1
1324	421	9.000	213.200	22	1	20	23	24	1	1
1101	363	9.000	324.000	\N	\N	20	20	18	1	1
1286	411	60.000	1643.200	\N	\N	20	49	1	1	1
1287	411	3.000	91.400	\N	\N	20	49	1	1	1
1288	411	60.000	1586.400	\N	\N	20	49	1	1	1
1289	411	4.000	123.750	\N	\N	20	49	1	1	1
1274	409	4.000	115.900	15	9	20	23	24	1	1
1275	409	8.000	205.350	15	7	20	23	24	1	1
1276	409	7.000	217.150	18	9	20	23	1	1	1
1277	409	8.000	223.700	18	7	20	23	1	1	1
1278	409	7.000	189.050	19	9	22	13	3	1	1
1279	409	9.000	202.350	19	7	22	13	3	1	1
1280	409	5.000	140.150	21	9	23	39	3	1	1
1281	409	6.000	137.400	21	1	23	39	3	1	1
1282	409	7.000	186.650	22	9	20	23	24	1	1
1283	409	7.000	183.900	22	1	20	23	24	1	1
1102	363	35.000	1571.060	\N	\N	20	2	1	1	1
1103	363	37.000	1651.410	\N	\N	20	53	1	1	1
1255	405	60.000	1556.350	\N	\N	20	49	1	1	1
1256	405	6.000	179.750	\N	\N	20	49	1	1	1
1339	424	25.000	900.000	\N	\N	20	19	18	1	1
1340	424	25.000	900.000	\N	\N	20	19	18	1	1
1468	448	11.000	396.000	\N	\N	20	20	18	1	1
1469	448	32.000	1451.110	\N	\N	20	2	1	1	1
1470	448	41.000	1838.080	\N	\N	20	1	1	1	1
1492	455	61.000	2766.960	\N	\N	20	2	15	1	1
1495	458	7.000	204.250	14	7	20	28	1	1	1
1496	458	8.000	242.550	14	9	20	28	1	1	1
1497	458	9.000	232.900	24	1	20	28	1	1	1
1498	458	8.000	234.300	24	9	20	28	1	1	1
1499	459	8.000	209.950	25	1	20	26	24	1	1
1500	459	7.000	204.200	25	9	20	26	24	1	1
1501	459	7.000	196.950	15	7	20	26	24	1	1
1502	459	7.000	199.950	15	46	20	26	24	1	1
1503	459	7.000	168.050	18	7	20	26	24	1	1
1504	459	7.000	216.400	18	46	20	26	24	1	1
1505	459	5.000	102.250	22	7	20	26	24	1	1
1506	459	5.000	140.150	22	46	20	26	24	1	1
1507	460	5.000	96.700	21	1	24	41	18	1	1
1508	460	4.000	94.250	21	9	24	41	18	1	1
1525	466	8.000	248.050	15	46	20	28	1	1	1
1526	466	8.000	230.550	24	1	20	28	1	1	1
1527	466	8.000	231.550	24	9	20	28	1	1	1
1530	468	7.000	170.700	25	1	20	26	24	1	1
1531	468	7.000	202.300	25	9	20	26	24	1	1
1532	468	1.000	30.500	15	7	20	26	24	1	1
1533	468	7.000	190.500	18	7	20	26	24	1	1
1534	468	7.000	214.500	18	46	20	26	24	1	1
1535	468	5.000	125.850	22	7	20	26	24	1	1
1361	427	2.000	43.300	14	1	20	23	24	1	1
1362	427	2.000	43.900	14	1	20	23	24	1	1
1363	427	10.000	296.050	14	30	20	23	24	1	1
1364	427	4.000	86.350	15	7	20	23	24	1	1
1365	427	12.000	344.450	15	9	20	23	24	1	1
1366	427	4.000	86.000	18	7	20	23	24	1	1
1367	427	12.000	341.800	18	9	20	23	24	1	1
1368	427	2.000	54.900	21	7	23	39	3	1	1
1369	427	7.000	181.100	21	9	23	39	3	1	1
1370	427	3.000	74.950	22	1	20	23	24	1	1
1371	427	10.000	306.000	22	9	20	23	24	1	1
1381	429	26.000	717.150	\N	\N	20	23	24	1	1
1382	429	31.000	803.300	\N	\N	20	23	24	1	1
1383	429	7.000	154.200	\N	\N	23	39	3	1	1
1384	429	31.000	804.100	\N	\N	20	23	24	1	1
1385	429	6.000	152.850	\N	\N	23	39	3	1	1
1386	430	3.000	136.080	\N	\N	20	1	4	1	1
1387	431	30.000	1360.800	\N	\N	20	13	15	1	1
1388	431	113.000	5125.680	\N	\N	20	15	14	1	1
1389	432	60.000	1658.050	\N	\N	20	23	24	1	1
1390	432	31.000	844.750	\N	\N	20	23	24	1	1
1391	432	18.000	407.950	\N	\N	23	39	3	1	1
1392	432	59.000	1422.350	\N	\N	22	13	3	1	1
1393	433	6.000	216.000	\N	\N	20	19	18	1	1
1394	434	8.000	207.800	14	1	20	23	24	1	1
1395	434	7.000	194.350	14	9	20	23	24	1	1
1396	434	8.000	200.800	15	7	20	23	24	1	1
1397	434	8.000	245.150	15	9	20	23	24	1	1
1398	434	1.000	30.050	21	1	23	39	24	1	1
1399	434	6.000	166.850	21	9	23	39	24	1	1
1400	434	8.000	200.650	22	1	20	23	24	1	1
1401	435	7.000	197.000	14	1	20	23	24	1	1
1402	435	7.000	209.250	14	9	20	23	24	1	1
1403	435	7.000	196.350	15	7	20	23	24	1	1
1404	435	9.000	228.250	15	46	20	23	24	1	1
1405	435	7.000	153.050	21	1	23	39	3	1	1
1406	435	2.000	58.150	21	9	23	39	3	1	1
1407	435	6.000	119.500	22	7	20	23	24	1	1
1408	435	7.000	165.950	22	46	20	23	24	1	1
1409	436	1.000	18.900	14	1	20	23	24	1	1
1410	436	8.000	222.050	14	9	20	23	24	1	1
1411	436	6.000	177.600	15	7	20	23	24	1	1
1412	436	4.000	75.100	21	7	23	39	3	1	1
1413	436	6.000	167.400	21	9	23	39	3	1	1
1414	436	1.000	17.450	22	7	20	23	24	1	1
1415	436	6.000	155.300	22	9	20	23	24	1	1
1416	437	50.000	2268.000	\N	\N	20	2	15	1	1
1471	449	11.000	305.550	\N	\N	20	26	24	1	1
1476	451	2.000	29.950	21	7	24	41	18	1	1
1477	451	3.000	82.450	21	9	24	41	18	1	1
1472	450	8.000	224.050	14	1	20	28	1	1	1
1473	450	8.000	239.950	14	46	20	28	1	1	1
1474	450	8.000	227.100	24	1	20	28	1	1	1
1475	450	8.000	234.650	24	9	20	28	1	1	1
1478	452	7.000	197.250	25	1	20	26	24	1	1
1479	452	7.000	209.100	25	9	20	26	24	1	1
1480	452	7.000	185.350	15	7	20	26	24	1	1
1481	452	7.000	207.850	15	46	20	26	24	1	1
1482	452	7.000	181.900	18	7	20	26	24	1	1
1483	452	7.000	217.100	18	46	20	26	24	1	1
1484	452	2.000	35.750	19	7	22	13	3	1	1
1372	428	7.000	194.900	14	1	20	23	24	1	1
1373	428	8.000	244.150	14	9	20	23	24	1	1
1374	428	9.000	232.350	15	7	20	23	24	1	1
1375	428	9.000	247.900	15	9	20	23	24	1	1
1376	428	8.000	201.200	18	7	20	23	24	1	1
1377	428	6.000	171.900	18	9	20	23	24	1	1
1378	428	4.000	82.150	21	1	23	39	3	1	1
1379	428	9.000	220.700	22	1	20	23	24	1	1
1380	428	8.000	221.750	22	9	20	23	24	1	1
1331	423	8.000	218.400	14	30	20	23	24	1	1
1332	423	9.000	256.200	14	1	20	23	24	1	1
1333	423	9.000	246.350	15	9	20	23	24	1	1
1334	423	9.000	247.500	15	7	20	23	24	1	1
1335	423	7.000	210.200	18	9	20	23	24	1	1
1336	423	9.000	255.500	18	7	20	23	24	1	1
1337	423	6.000	176.050	22	30	20	23	24	1	1
1338	423	9.000	213.350	22	1	20	23	24	1	1
1485	452	4.000	81.550	22	7	20	23	24	1	1
1486	453	60.000	1632.450	\N	\N	20	26	24	1	1
1487	453	33.000	873.050	\N	\N	20	26	24	1	1
1488	453	39.000	1008.500	\N	\N	20	26	24	1	1
1489	453	8.000	185.200	\N	\N	23	39	3	1	1
1490	453	21.000	516.800	\N	\N	22	13	3	1	1
1491	454	3.000	136.080	\N	\N	20	2	15	1	1
1493	456	30.000	990.000	\N	\N	24	41	18	1	1
1509	461	49.000	1308.500	\N	\N	20	26	24	1	1
1510	461	8.000	190.150	\N	\N	23	39	3	1	1
1341	425	8.000	229.650	14	30	20	23	24	1	1
1342	425	9.000	258.100	14	1	20	23	24	1	1
1343	425	8.000	220.650	15	9	20	23	24	1	1
1344	425	9.000	245.050	15	7	20	23	24	1	1
1345	425	8.000	226.050	18	9	20	23	24	1	1
1346	425	9.000	250.050	18	7	20	23	24	1	1
1347	425	4.000	101.850	21	9	23	39	3	1	1
1348	425	4.000	106.250	21	1	23	39	3	1	1
1349	425	7.000	191.500	22	30	20	23	24	1	1
1350	425	9.000	219.050	22	1	20	23	24	1	1
1351	426	9.000	252.850	14	30	20	23	24	1	1
1352	426	9.000	247.750	14	1	20	23	24	1	1
1353	426	9.000	246.500	15	9	20	23	24	1	1
1354	426	9.000	235.000	15	7	20	23	24	1	1
1355	426	9.000	253.050	18	9	20	23	24	1	1
1356	426	9.000	250.300	18	7	20	23	24	1	1
1357	426	6.000	143.900	21	9	23	39	3	1	1
1358	426	6.000	145.700	21	7	23	39	3	1	1
1359	426	7.000	211.000	22	30	20	23	24	1	1
1360	426	9.000	224.200	22	1	20	23	24	1	1
1422	440	60.000	1716.950	\N	\N	20	23	24	1	1
1423	440	28.000	784.250	\N	\N	20	23	24	1	1
1424	440	17.000	406.600	\N	\N	23	39	3	1	1
1511	461	26.000	745.400	\N	\N	20	26	24	1	1
1512	461	9.000	208.450	\N	\N	23	39	3	1	1
1516	464	33.000	693.000	\N	\N	20	20	18	1	1
1517	464	77.000	3458.840	\N	\N	20	2	1	1	1
1417	438	4.000	104.950	\N	\N	23	39	3	1	1
1418	438	60.000	1652.550	\N	\N	20	23	24	1	1
1419	438	32.000	857.150	\N	\N	20	23	24	1	1
1420	438	15.000	407.850	\N	\N	23	39	3	1	1
1421	439	3.000	72.100	\N	\N	23	39	3	1	1
1234	399	4.000	90.100	19	20	22	13	3	1	1
1235	399	4.000	156.100	21	9	23	39	3	1	1
1236	399	6.000	146.400	21	1	23	39	3	1	1
1518	464	10.000	360.000	\N	\N	20	20	18	1	1
1519	464	40.000	1778.160	\N	\N	20	2	1	1	1
1520	464	50.000	2252.340	\N	\N	20	1	1	1	1
1528	467	28.000	753.050	\N	\N	20	26	24	1	1
1429	442	6.000	162.850	14	1	20	23	24	1	1
1430	442	7.000	201.900	14	9	20	23	24	1	1
1431	442	3.000	73.600	15	7	20	23	24	1	1
1432	442	3.000	78.050	15	7	20	23	24	1	1
1433	442	7.000	216.850	15	46	20	23	24	1	1
1434	442	2.000	43.350	19	7	22	13	3	1	1
1435	442	5.000	142.250	19	46	22	13	3	1	1
1436	442	5.000	96.000	21	1	23	39	3	1	1
1437	442	2.000	61.600	21	9	23	39	3	1	1
1438	442	5.000	87.350	22	7	20	23	24	1	1
1439	442	6.000	165.850	22	46	20	23	24	1	1
1440	443	60.000	1581.150	\N	\N	20	23	24	1	1
1441	443	33.000	919.400	\N	\N	20	23	24	1	1
1442	443	17.000	401.350	\N	\N	23	39	3	1	1
1425	441	47.000	1203.900	\N	\N	20	26	24	1	1
1426	441	5.000	140.600	\N	\N	23	39	3	1	1
1427	441	1.000	21.000	\N	\N	23	39	3	1	1
1428	441	2.000	45.850	\N	\N	23	39	3	1	1
1529	467	27.000	751.500	\N	\N	20	26	24	1	1
1536	468	7.000	182.700	22	46	20	26	24	1	1
1537	469	4.000	87.300	21	1	24	39	18	1	1
1538	469	3.000	69.400	21	9	24	39	18	1	1
1539	470	60.000	1761.700	\N	\N	20	28	1	1	1
1544	473	27.000	759.450	\N	\N	20	26	24	1	1
1546	475	8.000	207.350	25	1	20	26	1	1	1
1547	475	7.000	207.400	25	9	20	26	1	1	1
1548	475	6.000	126.250	22	7	20	26	1	1	1
1549	475	8.000	193.550	22	46	20	26	1	1	1
1550	476	8.000	230.350	14	7	20	28	1	1	1
1551	476	8.000	234.950	14	46	20	28	1	1	1
1552	476	8.000	226.500	15	7	20	28	1	1	1
1553	476	8.000	246.400	15	46	20	28	1	1	1
1554	476	6.000	151.100	18	7	20	28	1	1	1
1555	476	8.000	232.400	24	1	20	28	1	1	1
1556	476	8.000	219.650	24	9	20	28	1	1	1
1557	477	4.000	85.050	21	1	24	41	18	1	1
1558	477	4.000	90.900	21	9	24	41	18	1	1
1559	478	51.000	1468.200	\N	\N	20	28	1	1	1
1561	480	30.000	990.000	\N	\N	24	41	\N	1	1
1566	482	7.000	186.900	14	7	20	28	24	1	1
1567	482	8.000	224.900	14	46	20	28	24	1	1
1568	482	7.000	199.950	15	7	20	28	24	1	1
1569	482	8.000	239.050	15	46	20	28	24	1	1
1570	482	7.000	184.850	24	1	20	28	24	1	1
1571	482	6.000	175.800	24	9	20	28	24	1	1
1572	483	4.000	116.300	18	7	20	31	19	1	1
1573	483	8.000	270.300	18	46	20	31	19	1	1
1574	484	4.000	73.550	21	1	24	41	18	1	1
1575	484	2.000	48.700	21	9	24	41	18	1	1
1562	481	7.000	174.200	25	1	20	23	24	1	1
1563	481	5.000	138.000	25	9	20	23	24	1	1
1564	481	4.000	64.200	22	7	20	23	24	1	1
1565	481	3.000	75.150	22	46	20	23	24	1	1
1576	485	15.000	680.400	\N	\N	20	1	14	1	1
1577	486	31.000	706.150	\N	\N	20	26	24	1	1
1578	486	27.000	700.750	\N	\N	20	26	24	1	1
1579	487	8.000	231.200	14	1	20	28	1	1	1
1580	487	8.000	234.450	14	20	20	28	1	1	1
1581	487	8.000	223.350	15	7	20	28	1	1	1
1582	487	9.000	250.100	15	46	20	28	1	1	1
1583	487	4.000	73.950	23	7	20	28	1	1	1
1584	487	6.000	153.800	23	46	20	28	1	1	1
1585	487	8.000	227.550	24	1	20	28	1	1	1
1586	487	8.000	232.450	24	20	20	28	1	1	1
1587	488	8.000	220.500	14	1	20	28	1	1	1
1588	488	8.000	233.550	14	20	20	28	1	1	1
1589	488	8.000	198.250	15	7	20	28	1	1	1
1590	488	9.000	249.000	15	46	20	28	1	1	1
1591	488	6.000	134.200	23	7	20	28	1	1	1
1592	488	7.000	186.000	23	46	20	28	1	1	1
1593	488	8.000	214.000	24	1	20	28	1	1	1
1594	488	8.000	230.350	24	20	20	28	1	1	1
1595	489	9.000	246.450	18	7	20	31	19	1	1
1596	489	5.000	148.400	18	46	20	31	19	1	1
1597	490	8.000	193.400	25	1	20	23	24	1	1
1598	490	8.000	204.600	25	20	20	23	24	1	1
1599	490	6.000	123.150	22	7	20	23	24	1	1
1600	490	8.000	161.550	22	46	20	23	24	1	1
1601	491	8.000	186.400	25	1	20	23	24	1	1
1602	491	8.000	196.850	25	20	20	23	24	1	1
1603	491	4.000	123.500	18	7	20	23	24	1	1
1604	491	10.000	255.450	18	46	20	23	24	1	1
1605	491	5.000	94.750	22	7	20	23	24	1	1
1606	491	7.000	163.050	22	46	20	23	24	1	1
1607	492	4.000	91.700	21	1	24	41	18	1	1
1608	492	2.000	38.900	21	20	24	41	18	1	1
1609	493	3.000	74.400	21	1	24	41	18	1	1
1610	493	4.000	91.850	21	20	24	41	18	1	1
1613	495	19.000	419.100	\N	\N	24	41	18	1	1
1614	496	1.000	45.360	\N	\N	20	13	19	1	1
1615	496	2.000	55.750	\N	\N	20	13	19	1	1
1611	494	51.000	1407.700	\N	\N	20	28	1	1	1
1612	494	51.000	1404.150	\N	\N	20	28	1	1	1
1619	498	51.000	1455.350	\N	\N	20	28	1	1	1
1620	499	8.000	225.350	14	1	20	28	1	1	1
1621	499	8.000	227.800	14	47	20	28	1	1	1
1622	499	9.000	249.500	15	7	20	28	1	1	1
1623	499	8.000	229.050	15	47	20	28	1	1	1
1624	499	7.000	178.450	23	7	20	28	1	1	1
1625	499	8.000	222.800	23	46	20	28	1	1	1
1626	499	8.000	215.250	24	1	20	28	1	1	1
1627	499	8.000	235.550	24	20	20	28	1	1	1
1628	500	8.000	187.550	25	1	20	23	24	1	1
1629	500	8.000	190.900	25	20	20	23	24	1	1
1630	500	10.000	217.900	18	7	20	23	24	1	1
1631	500	10.000	258.800	18	46	20	23	24	1	1
1632	500	7.000	144.250	22	7	20	23	24	1	1
1633	500	8.000	175.050	22	46	20	23	24	1	1
1634	501	4.000	86.850	21	1	24	41	18	1	1
1635	501	4.000	88.050	21	20	24	41	18	1	1
1636	502	54.000	1412.050	\N	\N	20	28	1	1	1
1637	503	60.000	1401.550	\N	\N	20	26	24	1	1
1638	504	21.000	630.100	\N	\N	20	31	19	1	1
1639	505	1.000	45.360	\N	\N	20	13	19	1	1
1640	506	2.000	68.600	\N	\N	20	13	17	1	1
1641	506	2.000	69.600	\N	\N	20	15	17	1	1
1642	506	1.000	45.360	\N	\N	20	15	17	1	1
1643	506	1.000	41.700	\N	\N	20	15	17	1	1
1560	479	15.000	332.650	\N	\N	24	41	18	1	1
1515	463	14.000	303.350	\N	\N	24	41	18	1	1
1545	474	1.000	10.800	\N	\N	22	13	1	1	1
1644	507	22.000	543.000	\N	\N	20	23	1	1	1
1646	509	34.000	754.450	\N	\N	20	26	24	1	1
1647	510	25.000	900.000	\N	\N	20	19	18	1	1
1648	510	20.000	720.000	\N	\N	20	19	18	1	1
1649	511	18.000	594.000	\N	\N	20	20	18	1	1
1650	511	38.000	1688.100	\N	\N	20	2	1	1	1
1651	511	49.000	2213.150	\N	\N	20	1	1	1	1
1655	513	8.000	212.650	14	1	20	28	1	1	1
1656	513	7.000	218.400	14	47	20	28	1	1	1
1657	513	8.000	226.900	15	7	20	28	1	1	1
1658	513	7.000	221.800	15	47	20	28	1	1	1
1659	513	7.000	179.800	23	7	20	28	1	1	1
1660	513	8.000	211.100	23	46	20	28	1	1	1
1661	513	8.000	211.950	24	1	20	28	1	1	1
1662	513	8.000	239.450	24	20	20	28	1	1	1
1668	515	7.000	182.450	18	7	20	23	1	1	1
1669	515	11.000	311.950	18	46	20	23	1	1	1
1670	516	3.000	66.000	21	1	24	41	18	1	1
1671	516	4.000	98.550	21	20	24	41	18	1	1
1672	517	15.000	339.450	\N	\N	24	41	18	1	1
1673	518	31.000	746.700	\N	\N	20	26	24	1	1
1674	518	14.000	362.000	\N	\N	20	23	24	1	1
1663	514	7.000	179.150	25	1	20	26	24	1	1
1664	514	7.000	192.600	25	20	20	26	24	1	1
1665	514	2.000	49.350	18	7	20	26	24	1	1
1666	514	6.000	120.200	22	7	20	26	24	1	1
1667	514	7.000	162.550	22	46	20	26	24	1	1
1676	520	8.000	205.100	25	1	20	23	24	1	1
1677	520	6.000	180.050	25	20	20	23	24	1	1
1678	520	2.000	35.000	20	7	20	23	24	1	1
1679	520	7.000	152.750	22	7	20	23	24	1	1
1680	520	6.000	130.150	22	47	20	23	24	1	1
1681	521	8.000	229.350	14	1	20	28	1	1	1
1682	521	7.000	219.350	14	47	20	28	1	1	1
1683	521	8.000	214.550	15	7	20	28	1	1	1
1684	521	8.000	235.750	15	47	20	28	1	1	1
1685	521	7.000	178.400	23	7	20	28	1	1	1
1686	521	8.000	218.700	23	46	20	28	1	1	1
1687	521	8.000	218.500	24	1	20	28	1	1	1
1688	521	8.000	223.200	24	20	20	28	1	1	1
1691	523	10.000	290.250	18	7	20	31	19	1	1
1692	523	11.000	310.250	18	46	20	31	19	1	1
1693	524	30.000	990.000	\N	\N	24	41	18	1	1
1652	512	10.000	453.600	\N	\N	20	13	19	1	1
1653	512	7.000	317.520	\N	\N	20	1	1	1	1
1654	512	4.000	144.000	\N	\N	20	19	18	1	1
1616	497	11.000	498.960	\N	\N	20	13	19	1	1
1617	497	7.000	317.520	\N	\N	20	1	19	1	1
1618	497	1.000	72.000	\N	\N	20	19	18	1	1
1689	522	4.000	96.000	21	1	24	41	18	1	1
1690	522	4.000	87.250	21	20	24	41	18	1	1
1645	508	50.000	1402.500	\N	\N	20	28	1	1	1
1694	525	8.000	226.850	14	1	20	28	1	1	1
1695	525	8.000	227.800	14	47	20	28	1	1	1
1696	525	8.000	208.550	15	7	20	28	1	1	1
1697	525	7.000	217.850	15	47	20	28	1	1	1
1698	525	8.000	174.300	23	7	20	28	1	1	1
1699	525	7.000	206.900	23	46	20	28	1	1	1
1700	525	8.000	226.650	24	1	20	28	1	1	1
1701	525	8.000	236.000	24	20	20	28	1	1	1
1702	526	7.000	174.800	25	1	20	23	24	1	1
1703	526	7.000	188.350	25	20	20	23	24	1	1
1704	526	8.000	158.100	22	7	20	23	24	1	1
1705	526	7.000	192.100	22	46	20	23	24	1	1
1706	527	4.000	93.850	21	1	24	41	18	1	1
1707	527	4.000	91.700	21	20	24	41	18	1	1
1708	528	9.000	249.500	18	7	20	31	19	1	1
1709	528	10.000	288.100	18	46	20	31	19	1	1
1711	530	29.000	746.150	\N	\N	20	26	24	1	1
1710	529	51.000	1412.800	\N	\N	20	28	1	1	1
1712	531	51.000	1410.150	\N	\N	20	28	1	1	1
1675	519	49.000	1404.950	\N	\N	20	28	1	1	1
1713	532	5.000	130.700	25	1	20	23	24	1	1
1714	532	6.000	182.950	25	20	20	23	24	1	1
1715	532	5.000	131.000	22	7	20	23	24	1	1
1716	533	7.000	198.750	14	1	20	28	1	1	1
1717	533	7.000	221.200	14	47	20	28	1	1	1
1718	533	7.000	189.700	15	7	20	28	1	1	1
1719	533	7.000	222.650	15	47	20	28	1	1	1
1720	533	5.000	111.500	23	7	20	28	1	1	1
1721	533	7.000	189.650	23	46	20	28	1	1	1
1722	533	7.000	188.500	24	1	20	28	1	1	1
1723	533	8.000	238.700	24	20	20	28	1	1	1
1724	534	3.000	80.600	21	1	24	41	18	1	1
1725	534	4.000	93.550	21	47	24	41	18	1	1
1726	535	8.000	229.850	18	7	20	31	19	1	1
1727	535	3.000	96.350	18	46	20	31	19	1	1
1728	535	1.000	26.900	22	7	20	23	19	1	1
1729	536	22.000	726.000	\N	\N	20	20	18	1	1
1730	536	34.000	1542.240	\N	\N	20	2	1	1	1
1731	536	45.000	2020.520	\N	\N	20	1	1	1	1
1732	537	49.000	1407.500	\N	\N	20	28	1	1	1
1733	538	2.000	90.720	\N	\N	20	13	24	1	1
1734	538	1.000	8.000	\N	\N	20	13	24	1	1
1735	539	13.000	589.680	\N	\N	20	13	19	1	1
1736	539	5.000	226.800	\N	\N	20	1	26	1	1
1737	540	2.000	90.720	\N	\N	20	13	21	1	1
1738	540	5.000	226.800	\N	\N	20	2	21	1	1
1739	540	6.000	272.160	\N	\N	20	1	26	1	1
1740	540	2.000	90.720	\N	\N	20	13	21	1	1
1741	540	6.000	272.160	\N	\N	20	1	26	1	1
1742	540	5.000	226.800	\N	\N	20	2	21	1	1
1743	540	1.000	45.360	\N	\N	20	1	26	1	1
1744	540	11.000	498.960	\N	\N	20	1	26	1	1
1745	540	10.000	453.600	\N	\N	20	1	26	1	1
1746	540	8.000	288.000	\N	\N	20	19	26	1	1
1767	543	7.000	317.520	\N	\N	20	1	14	1	1
1768	544	1.000	24.700	25	1	20	28	1	1	1
1769	544	7.000	210.700	25	20	20	28	1	1	1
1770	544	7.000	200.500	14	7	20	28	1	1	1
1771	544	8.000	226.100	14	47	20	28	1	1	1
1772	544	7.000	213.950	15	7	20	28	1	1	1
1773	544	8.000	233.350	15	47	20	28	1	1	1
1774	544	7.000	152.200	23	7	20	28	1	1	1
1775	544	8.000	215.250	23	46	20	28	1	1	1
1776	544	7.000	197.350	24	1	20	28	1	1	1
1777	544	8.000	237.500	24	20	20	28	1	1	1
1778	545	8.000	169.700	22	7	20	23	24	1	1
1779	545	8.000	204.700	22	46	20	23	24	1	1
1780	546	1.000	17.050	25	1	20	23	24	1	1
1781	546	3.000	61.150	22	7	20	23	24	1	1
1782	546	8.000	201.100	22	46	20	23	24	1	1
1783	547	7.000	206.500	25	1	20	28	1	1	1
1784	547	8.000	227.550	25	20	20	28	1	1	1
1785	547	8.000	225.750	14	1	20	28	1	1	1
1786	547	8.000	235.300	14	20	20	28	1	1	1
1787	547	7.000	186.050	15	7	20	28	1	1	1
1788	547	8.000	240.500	15	46	20	28	1	1	1
1789	547	7.000	197.650	23	7	20	28	1	1	1
1790	547	6.000	183.400	23	46	20	28	1	1	1
1791	547	8.000	222.400	24	1	20	28	1	1	1
1792	547	7.000	206.350	24	20	20	28	1	1	1
1793	548	4.000	93.050	21	1	24	41	18	1	1
1794	548	4.000	98.850	21	20	24	41	18	1	1
1799	551	4.000	108.000	18	7	20	33	19	1	1
1800	551	9.000	263.250	18	46	20	33	19	1	1
1801	552	8.000	234.850	18	7	20	33	19	1	1
1802	552	9.000	261.150	18	46	20	33	19	1	1
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
236	5	2026-08-19	20260820	14	16	\N	13	\N	\N	Style#158374	1
297	3	2026-08-31	170527	13	13	\N	13	\N	\N	CUS-0090	1
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
412	5	2026-09-28	20260928	14	16	\N	\N	\N	\N	\N	1
209	6	2026-08-11	3759	13	13	\N	13	960+720+370	\N	3759 	1
161	6	2026-08-01	3735	13	13	\N	13	960+720+370	\N	3735	1
222	4	2026-08-11	3764	13	13	\N	\N	\N	\N	3764	1
216	6	2026-08-11	3761	14	16	\N	4	1160	245	3761	1
191	6	2026-08-10	3755,3756,3757	15	14	\N	13	940+640+384	\N	3755,3756,3757	1
309	4	2026-08-27	3789	14	16	\N	16	\N	\N	STYLE#156229	1
255	5	2026-08-22	20260822	14	16	\N	16	\N	\N	STYLE#158374	1
258	5	2026-08-23	20260823	14	16	\N	13	\N	\N	STYLE#158374	1
286	5	2026-07-31	August-26 >----> Opening	\N	20	\N	1	620	115	August-26 >----> Opening	1
169	3	2026-08-04	852	14	16	\N	13	\N	\N	\N	1
299	5	2026-08-31	20260831	13	13	\N	13	\N	\N	\N	1
201	5	2026-07-31	August-26 >----> Opening	13	13	\N	13	\N	\N	August-26 >----> Opening	1
218	6	2026-08-13	3767,3768	15	14	\N	13	940+640+384	340	3767,3768	1
224	6	2026-08-17	3771,3772	15	14	\N	13	940+640+384	240	3771,3772	1
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
249	6	2026-08-20	3778	14	16	\N	16	820	\N	Style#158374	1
227	5	2026-08-16	20260816	14	16	\N	\N	\N	\N	20260816	1
284	5	2026-08-02	4700015024	16	15	\N	13	1020+740+410	240	20260817	1
226	5	2026-08-15	20260815	14	16	\N	\N	\N	\N	\N	1
279	5	2026-08-10	4700015020	14	16	\N	16	820	245	762	1
207	5	2026-07-31	August-26 >----> Opening	17	17	\N	13	\N	\N	August-26 >----> Opening	1
259	5	2026-08-23	20260823	17	17	\N	16	\N	\N	\N	1
301	5	2026-09-01	20260901	13	13	\N	13	\N	\N	\N	1
251	5	2026-08-21	202608021	14	16	\N	16	\N	\N	Style#158374	1
290	3	2026-08-29	170468	13	13	\N	13	\N	\N	CUS-0090	1
293	5	2026-08-30	4700015027	13	13	\N	13	\N	\N	CUS-0090	1
295	6	2026-08-29	3793,3794,3795	\N	16	\N	\N	\N	\N	STYLE#158374	1
220	6	2026-08-13	3770	14	16	\N	\N	1000+740+380	240	3770	1
303	6	2026-09-02	3800	13	13	\N	13	\N	\N	\N	1
304	6	2026-09-01	3798	13	13	\N	13	\N	\N	CUS-0090	1
274	3	2026-08-25	3801	14	16	\N	16	\N	\N	3801	1
308	4	2026-08-25	3788	14	16	\N	13	\N	\N	STYLE#156229	1
277	5	2026-08-27	20260817	14	16	\N	1	820	145	\N	1
305	3	2026-09-02	2228,2223	14	16	\N	13	\N	\N	For New Order	1
310	5	2026-09-03	20260903	16	15	\N	13	\N	\N	\N	1
312	5	2026-09-03	20260903	17	17	\N	\N	\N	\N	\N	1
307	5	2026-09-02	20260902	17	17	\N	\N	\N	\N	\N	1
306	5	2026-09-02	20260902	13	13	\N	13	\N	\N	\N	1
311	5	2026-09-03	20260903	13	13	\N	13	\N	\N	\N	1
314	3	2026-09-03	2236	14	16	\N	13	\N	\N	Style#158375	1
315	3	2026-09-03	170641	13	13	\N	13	\N	\N	CUS-0090	1
316	3	2026-09-02	1434	17	17	\N	13	\N	\N	\N	1
318	6	2026-09-03	3802	\N	13	\N	13	\N	\N	\N	1
273	6	2026-08-27	3790,3791	14	16	\N	\N	1000+700+385	250	3790,3791	1
317	6	2026-09-03	3801,3803,3804	14	16	\N	\N	\N	\N	STYLE#158374	1
182	3	2026-07-31	August-26 >----> Opening	\N	16	\N	\N	\N	\N	August-26 >----> Opening	1
288	3	2026-08-28	GP2608-284,GP2608-288	16	15	\N	13	\N	\N	\N	1
313	3	2026-09-03	GP2609.28	16	15	\N	13	\N	\N	\N	1
275	3	2026-08-25	GP#2608-269	16	15	\N	13	\N	\N	\N	1
151	3	2026-08-05	4700015011	\N	14	\N	13	\N	\N	4700015011	1
179	6	2026-08-07	3751,3752	15	14	\N	13	\N	\N	\N	1
413	5	2026-09-24	20260924	\N	22	\N	\N	\N	\N	\N	1
150	5	2026-08-04	20260804	15	14	\N	13	\N	\N	\N	1
158	3	2026-08-04	0268	14	16	\N	4	\N	\N	\N	1
162	6	2026-08-03	3736	13	13	\N	13	960+720+370	\N	\N	1
132	5	2026-08-01	20260801-01	15	14	13	13	\N	\N	20260801-01	1
269	4	2026-08-20	3775	18	19	\N	16	\N	\N	Yarn Return	1
140	5	2026-08-01	20260801-01	16	15	\N	13	\N	\N	20260801-01	1
272	6	2026-08-25	3785,3786,3787	17	17	\N	13	1020+680+415	330	3785,3786,3787	1
166	5	2026-08-07	20260807	13	13	\N	13	960+720+370	\N	\N	1
228	5	2026-08-17	20260817	14	16	\N	13	\N	\N	\N	1
133	5	2026-08-02	20260802-01	15	14	\N	13	\N	\N	20260802-01	1
134	5	2026-08-03	20260803-01	15	14	\N	13	\N	\N	20260803-01	1
135	5	2026-08-01	20260801-01	17	17	\N	13	\N	\N	20260801-01	1
137	5	2026-08-01	20260801-01	\N	20	\N	13	\N	\N	20260802-01	1
138	5	2026-08-01	20260801-01	14	16	\N	4	\N	\N	20260801-01	1
141	5	2026-08-02	20260802-01	13	13	\N	13	\N	\N	20260802-01	1
142	5	2026-08-02	20260802-01	16	15	\N	13	\N	\N	20260802-01	1
144	5	2026-08-03	20260803-01	13	13	\N	13	\N	\N	20260803-01	1
257	5	2026-08-22	20260822	17	17	\N	16	\N	\N	\N	1
176	6	2026-08-06	3747,3748	15	14	\N	13	\N	\N	\N	1
178	6	2026-08-07	3750	13	13	\N	13	\N	\N	\N	1
180	6	2026-08-08	3753	13	13	\N	13	\N	\N	\N	1
285	5	2026-08-01	4700015025	17	17	\N	13	1050+700+405	250	20260817	1
170	6	2026-08-04	3738	13	13	\N	13	\N	\N	\N	1
213	5	2026-08-13	20260813	14	16	\N	1	820	140	20260813	1
211	5	2026-08-12	20260812	14	16	\N	1	820	140	20260812	1
148	5	2026-08-04	20260804	14	16	\N	13	\N	\N	20260804	1
164	3	2026-07-31	August-26 >----> Opening	\N	14	\N	13	\N	\N	August-26 >----> Opening	1
184	3	2026-07-31	August-26 >----> Opening	\N	20	\N	13	\N	\N	August-26 >----> Opening	1
186	5	2026-08-08	20260808	13	13	\N	13	\N	\N	\N	1
188	5	2026-08-08	20260808	15	14	\N	13	\N	\N	\N	1
190	6	2026-08-10	3754	13	13	\N	13	\N	\N	\N	1
192	3	2026-08-10	0320	14	16	\N	13	\N	\N	\N	1
172	6	2026-08-04	3740,3741,3742	\N	16	\N	\N	\N	\N	\N	1
139	5	2026-08-01	20260801-01	13	13	\N	13	\N	\N	20260801-01	1
160	3	2026-08-01	169808	13	13	\N	13	\N	\N	\N	1
198	5	2026-08-10	20260810	15	14	\N	13	\N	\N	\N	1
291	5	2026-08-29	20260829	13	13	\N	13	\N	\N	\N	1
208	5	2026-08-12	20260812	15	14	\N	13	940+640+384	340	\N	1
278	5	2026-08-27	4700015019	16	15	\N	13	1020+740+410	235	762	1
217	6	2026-08-11	3762	14	16	\N	13	1060+730+410	200	3762	1
247	6	2026-08-20	3777	14	16	\N	16	820	\N	3777	1
219	6	2026-08-13	3769	14	16	\N	4	1160	240	3769	1
221	4	2026-08-11	3763	13	13	\N	\N	\N	\N	3763	1
152	3	2026-08-03	4700014961	15	14	18	13	\N	\N	4700014961	1
196	3	2026-08-05	4700015011	15	14	18	13	\N	\N	4700015011	1
223	4	2026-08-15	3766	15	14	\N	13	\N	\N	3766	1
231	5	2026-08-18	20260818	14	16	\N	16	\N	\N	\N	1
233	6	2026-08-18	3774	14	16	\N	13	1000+700+385	368	Style#158374	1
235	6	2026-08-18	3774	14	16	\N	16	820	\N	Style#158374	1
237	5	2026-08-19	20260819	14	16	\N	16	\N	\N	Style#158374	1
239	3	2026-08-18	1483	17	17	\N	13	\N	\N	1483	1
240	3	2026-08-18	1484	17	17	\N	13	\N	\N	1484	1
242	5	2026-08-20	20260820	14	16	\N	13	\N	\N	\N	1
243	5	2026-08-20	20260820	14	16	\N	16	\N	\N	\N	1
245	3	2026-08-20	1489	17	17	\N	13	\N	\N	\N	1
250	5	2026-08-21	20260821	14	16	\N	13	\N	\N	Style#158374	1
253	3	2026-08-21	1492	17	17	\N	16	\N	\N	1492	1
254	3	2026-08-21	1493	17	17	\N	16	\N	\N	1493	1
298	6	2026-08-31	3797	16	15	\N	13	1020+740+410	\N	3797	1
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
292	5	2026-08-29	20260829	16	15	\N	13	\N	\N	\N	1
294	6	2026-08-29	3792	16	15	\N	13	1020+740+410	\N	\N	1
296	6	2026-08-31	3796	13	13	\N	13	960+720+370	\N	CUS-0090	1
215	6	2026-08-11	3760	14	16	\N	13	1060+730+410	200	3760	1
300	3	2026-08-31	261225	14	16	\N	13	\N	\N	For New Order	1
302	6	2026-09-01	3799	14	16	\N	\N	\N	\N	Style#158374	1
143	5	2026-08-03	20260803	14	16	\N	\N	\N	\N	\N	1
200	6	2026-08-01	3734	\N	20	\N	1	\N	\N	3734	1
230	5	2026-08-18	20260818	14	16	\N	13	\N	\N	\N	1
136	5	2026-08-02	20260802	14	16	\N	\N	\N	\N	20260802	1
204	5	2026-08-11	20260811-1	14	16	\N	\N	\N	\N	20260811-1	1
168	3	2026-08-06	4700015011	15	14	\N	13	\N	\N	4700015011	1
174	6	2026-08-05	3744,3745	15	14	\N	13	\N	\N	\N	1
225	4	2026-08-17	3773	15	14	\N	13	\N	\N	3773	1
319	6	2026-09-04	3806,3807	17	17	\N	\N	1020+680+415	\N	3806,3807	1
320	6	2026-09-04	3805	13	13	\N	13	\N	\N	CUS-0090	1
321	5	2026-09-04	20260904	16	15	\N	13	\N	\N	\N	1
322	5	2026-09-04	20260904	17	17	\N	\N	\N	\N	\N	1
323	5	2026-09-04	20260904	13	13	\N	13	\N	\N	\N	1
324	6	2026-09-05	3808	13	13	\N	13	1020+740+410	\N	CUS-0090	1
326	5	2026-09-05	20260805	13	13	\N	13	\N	\N	\N	1
327	5	2026-09-06	20260906	13	13	\N	13	\N	\N	\N	1
328	3	2026-09-05	1368512	14	16	\N	13	\N	\N	\N	1
193	5	2026-07-31	August-26 >----> Opening	\N	16	\N	\N	\N	\N	August-26 >----> Opening	1
329	5	2026-08-11	20260811	14	16	\N	13	\N	\N	\N	1
330	6	2026-09-07	3809	16	15	\N	13	\N	\N	\N	1
333	6	2026-09-07	3812,3813,3814	14	16	\N	\N	\N	\N	STYLE#158375	1
334	6	2026-09-07	3810	13	13	\N	13	\N	\N	CUS-0090	1
335	4	2026-09-07	3811	13	13	\N	13	\N	\N	CUS-0090	1
336	3	2026-09-07	DC-0261394, DC-0261395	14	16	\N	13	\N	\N	1424,1425	1
386	5	2026-09-21	20260921	15	14	\N	13	\N	\N	\N	1
387	6	2026-09-21	3843,3844	15	14	\N	13	\N	\N	4700015553	1
340	5	2026-09-08	20260908	14	16	\N	\N	\N	\N	\N	1
341	5	2026-09-08	20260908	17	17	\N	13	\N	\N	\N	1
342	3	2026-09-08	261405	14	16	\N	13	\N	\N	\N	1
344	6	2026-09-09	3815,3816	13	13	\N	13	\N	\N	CUS-0090	1
347	5	2026-09-09	20260909	\N	23	\N	13	\N	\N	\N	1
348	3	2026-09-08	20260908	\N	22	\N	\N	\N	\N	20260908	1
350	5	2026-09-10	4700015028	14	16	\N	\N	\N	\N	Style#158375	1
351	3	2026-09-10	24345	14	16	\N	16	\N	\N	R-5	1
354	5	2026-09-11	20260911	15	14	\N	13	\N	\N	\N	1
353	5	2026-09-11	20260911	14	16	\N	13	\N	\N	\N	1
355	3	2026-09-11	1531	14	16	\N	13	\N	\N	\N	1
331	3	2026-08-25	GP2608-273	16	15	\N	13	\N	\N	\N	1
356	5	2026-09-12	20260912	15	14	\N	13	\N	\N	\N	1
357	5	2026-09-13	20260913	15	14	\N	13	\N	\N	\N	1
358	5	2026-09-12	20260912	14	16	\N	13	\N	\N	\N	1
359	5	2026-09-13	20260913	14	16	\N	13	\N	\N	\N	1
360	6	2026-09-12	3823	25	23	\N	13	\N	\N	Simple	1
364	4	2026-09-14	3828	16	15	\N	13	\N	\N	Yarn Return	1
338	5	2026-09-07	20260907	13	13	\N	13	\N	\N	\N	1
325	5	2026-09-05	20260905	17	17	\N	13	\N	\N	\N	1
337	5	2026-09-07	20260907	\N	16	\N	\N	\N	\N	\N	1
365	5	2026-09-14	20260914	15	14	\N	13	\N	\N	\N	1
343	3	2026-09-08	1668,11456	25	23	\N	13	\N	\N	For Simple	1
366	5	2026-09-14	20260914	14	16	\N	13	\N	\N	\N	1
361	4	2026-09-12	3824	25	23	\N	13	\N	\N	Loose Yarn Return (HN Knit)	1
368	6	2026-09-15	3831,3832	14	16	\N	\N	\N	\N	Style#158375	1
369	4	2026-09-15	3833	14	16	\N	13	\N	\N	\N	1
370	5	2026-09-15	20260915	14	16	\N	13	\N	\N	\N	1
371	5	2026-09-15	20260915	15	14	\N	13	\N	\N	\N	1
372	5	2026-09-16	20260916	15	14	\N	13	\N	\N	\N	1
373	5	2026-09-16	20260916	14	16	\N	13	\N	\N	\N	1
349	6	2026-09-10	3818,3819,3820,3821,3822	14	16	\N	\N	\N	\N	Style#158375	1
346	5	2026-09-09	20260909	14	16	\N	\N	\N	\N	\N	1
405	6	2026-09-25	3854,3855	15	14	\N	13	\N	\N	4700015594	1
374	5	2026-09-17	20260917	\N	14	\N	13	\N	\N	\N	1
377	6	2026-09-16	3834,3835	15	14	\N	13	\N	\N	4700015497	1
378	5	2026-09-18	20260918	15	14	\N	13	\N	\N	\N	1
379	5	2026-09-19	20260919	15	14	\N	13	\N	\N	\N	1
380	5	2026-09-20	20260920	15	14	\N	13	\N	\N	\N	1
402	6	2026-09-24	3851	14	16	\N	13	\N	\N	STYLE#158375	1
381	5	2026-09-19	4700015554	14	16	\N	\N	\N	\N	4700015497	1
388	5	2026-09-14	20260914	14	16	\N	13	\N	\N	\N	1
389	5	2026-09-22	20260922	15	14	\N	13	\N	\N	\N	1
393	5	2026-09-23	20260923	14	16	\N	\N	\N	\N	\N	1
396	4	2026-09-23	3850	13	13	\N	13	\N	\N	\N	1
391	3	2026-09-21	4700015594	15	14	\N	13	\N	\N	4700015594	1
397	6	2026-09-23	3846,3847,3848,3849	15	14	\N	13	\N	\N	4700015573	1
383	6	2026-09-19	3839,3840	14	16	\N	\N	\N	\N	STYLE#158375	1
400	6	2026-09-24	3852,3853	15	14	\N	13	\N	\N	4700015594	1
392	5	2026-09-23	20260923	15	14	\N	13	\N	\N	\N	1
398	5	2026-09-24	20260924	15	14	\N	13	\N	\N	\N	1
403	5	2026-09-25	20260925	15	14	\N	13	\N	\N	\N	1
404	5	2026-09-25	20260925	14	16	\N	\N	\N	\N	HG	1
407	5	2026-09-26	20260926	14	16	\N	\N	\N	\N	\N	1
408	5	2026-09-27	20260927	15	14	\N	13	\N	\N	\N	1
411	6	2026-09-28	3856,3857,3858,3859	15	14	\N	13	\N	\N	4700015635	1
409	5	2026-09-27	20260926	14	16	\N	\N	\N	\N	\N	1
406	5	2026-09-26	20260926	15	14	\N	13	\N	\N	\N	1
363	3	2026-09-12	4700015497	15	14	\N	13	\N	\N	4700015497	1
352	3	2026-09-10	4700015481	15	14	\N	13	\N	\N	4700015481	1
367	6	2026-09-15	3829,3830	15	14	\N	13	\N	\N	4700015481	1
362	6	2026-09-14	3825,3826,3827	15	14	\N	13	\N	\N	4700015481	1
414	6	2026-09-28	3860	14	16	\N	1	\N	\N	STYLE#158375	1
401	3	2026-09-24	381	14	16	\N	13	\N	\N	ST#NOS	1
384	6	2026-09-21	3841,3842	15	14	\N	13	\N	\N	4700015553	1
345	6	2026-09-09	3817	17	17	\N	\N	\N	\N	Style#GC-101	1
375	3	2026-09-17	4700015553	15	14	\N	13	\N	\N	4700015553	1
382	3	2026-09-19	4700015573	15	14	\N	13	\N	\N	4700015573	1
395	3	2026-09-23	4700015635	15	14	\N	13	\N	\N	4700015635	1
376	6	2026-09-18	3837,3838	15	14	\N	13	\N	\N	4700015497	1
390	5	2026-09-22	20260922	14	16	\N	16	\N	\N	\N	1
385	4	2026-09-18	3836	16	15	\N	13	\N	\N	\N	1
399	5	2026-09-24	20260924	14	16	\N	\N	\N	\N	\N	1
410	5	2026-09-28	20260929	15	14	\N	13	\N	\N	\N	1
415	3	2026-09-28	389	14	16	\N	13	\N	\N	\N	1
416	6	2026-09-29	3861,3862,3863	14	16	\N	\N	\N	\N	3861,3862,3863	1
417	3	2026-09-26	984	14	16	\N	13	\N	\N	\N	1
419	6	2026-09-30	3865	14	16	\N	\N	\N	\N	ST#NOS	1
171	6	2026-08-04	3739	\N	20	\N	13	\N	\N	\N	1
420	6	2026-09-30	3866	14	16	\N	13	\N	\N	Style#158375	1
421	5	2026-09-30	20260930	14	16	\N	13	\N	\N	\N	1
422	5	2026-09-29	20260929	14	16	\N	13	\N	\N	\N	1
418	4	2026-09-29	3864	15	14	\N	13	\N	\N	4700015635	1
424	3	2026-10-02	2241,2240	14	16	\N	13	\N	\N	2241,2240	1
427	5	2026-10-04	20261004	14	16	\N	\N	\N	\N	\N	1
480	3	2026-10-16	Withoutchallan	26	21	\N	4	\N	\N	\N	1
429	6	2026-10-05	3867,3868,3869	14	16	\N	\N	\N	\N	ST#NOS	1
430	3	2026-10-03	6353	14	16	\N	13	\N	\N	\N	1
431	3	2026-10-06	0262031,10260000307	14	16	\N	13	\N	\N	\N	1
432	6	2026-10-06	3870,3871,3873	14	16	\N	\N	\N	\N	3870,3871,3873	1
433	4	2026-10-06	3872	14	16	\N	13	\N	\N	Yarn Return	1
434	5	2026-10-06	20261006	14	16	\N	\N	\N	\N	\N	1
435	5	2026-10-08	20261008	14	16	\N	13	\N	\N	\N	1
436	5	2026-10-07	20261007	14	16	\N	\N	\N	\N	\N	1
437	3	2026-10-07	2098	14	16	\N	13	\N	\N	\N	1
428	5	2026-10-05	20261005	14	16	\N	\N	\N	\N	\N	1
423	5	2026-10-01	202601001	14	16	\N	13	\N	\N	\N	1
425	5	2026-10-02	20261002	14	16	\N	\N	\N	\N	\N	1
426	5	2026-10-03	20261003	14	16	\N	\N	\N	\N	\N	1
440	6	2026-10-08	3878,3879	14	16	\N	\N	\N	\N	3878,3879	1
482	5	2026-10-16	20261016	15	14	\N	13	\N	\N	\N	1
438	6	2026-10-07	3874,3875,3876	14	16	\N	\N	\N	\N	3874,3875,3876	1
439	6	2026-10-08	3877	14	16	\N	16	\N	\N	\N	1
442	5	2026-10-09	20261009	14	16	\N	13	\N	\N	\N	1
443	6	2026-10-09	3883,3884	14	16	\N	\N	\N	\N	ST#NOS	1
441	6	2026-10-09	3880,3880,3881,3882	14	16	\N	\N	\N	\N	\N	1
444	5	2026-10-10	20261010	14	16	\N	\N	\N	\N	\N	1
446	5	2026-10-11	20261011	15	14	\N	13	\N	\N	\N	1
447	3	2026-10-10	0262102	14	16	\N	13	\N	\N	\N	1
448	3	2026-10-10	4700015790	15	14	\N	13	\N	\N	4700015790	1
449	6	2026-10-10	3885	14	16	\N	13	\N	\N	\N	1
445	5	2026-10-11	20261011	14	16	\N	\N	\N	\N	\N	1
451	5	2026-10-12	20261012	26	21	\N	4	\N	\N	\N	1
450	5	2026-10-12	20261012	15	14	\N	13	\N	\N	\N	1
452	5	2026-10-12	20261012	14	16	\N	13	\N	\N	\N	1
453	6	2026-10-12	3887,3888,3889,3890	14	16	\N	\N	\N	\N	STYLE#158186,163255	1
454	4	2026-10-12	3886	14	16	\N	13	\N	\N	\N	1
455	3	2026-10-12	0262133	14	16	\N	13	\N	\N	\N	1
456	3	2026-10-10	Withoutchallan	26	21	\N	4	\N	\N	\N	1
457	3	2026-10-13	124	14	16	\N	13	\N	\N	\N	1
458	5	2026-10-13	20261013	15	14	\N	13	\N	\N	\N	1
459	5	2026-10-13	20261013	14	16	\N	13	\N	\N	\N	1
460	5	2026-10-13	20261013	26	21	\N	4	\N	\N	\N	1
461	6	2026-10-13	3891,3894	14	16	\N	13	\N	\N	3891,3894	1
462	6	2026-10-13	3892,3893	15	14	\N	13	\N	\N	4700015790	1
464	3	2026-10-14	4700015820,4700015813	15	14	\N	13	\N	\N	4700015820,4700015813	1
465	3	2026-10-14	4700015820	15	14	\N	13	\N	\N	4700015820	1
466	5	2026-10-14	20261014	15	14	\N	13	\N	\N	\N	1
467	6	2026-10-14	3896,3897	14	16	\N	13	\N	\N	STYLE#163255	1
468	5	2026-10-14	20261014	14	16	\N	13	\N	\N	\N	1
469	5	2026-10-14	20261014	26	21	\N	13	\N	\N	\N	1
470	6	2026-10-15	3898	15	14	\N	13	\N	\N	470015790	1
473	6	2026-10-15	3899	14	16	\N	\N	\N	\N	Style#163255	1
475	5	2026-10-15	20261015	14	16	\N	13	\N	\N	\N	1
476	5	2026-10-15	20261015	15	14	\N	13	\N	\N	\N	1
477	5	2026-10-15	20261015	26	21	\N	4	\N	\N	\N	1
478	6	2026-10-16	3901	15	14	\N	13	\N	\N	4700015813	1
483	5	2026-10-16	20261016	17	17	\N	13	\N	\N	\N	1
484	5	2026-10-16	20261016	26	21	\N	4	\N	\N	\N	1
481	5	2026-10-16	20261016	14	16	\N	13	\N	\N	\N	1
485	3	2026-10-17	4253	14	16	\N	13	\N	\N	\N	1
486	6	2026-10-17	3905,3904	14	16	\N	13	\N	\N	Style#163255	1
487	5	2026-10-17	20261019	15	14	\N	13	\N	\N	\N	1
488	5	2026-10-18	20261018	15	14	\N	13	\N	\N	\N	1
489	5	2026-10-17	20261017	17	17	\N	13	\N	\N	\N	1
490	5	2026-10-17	20261017	14	16	\N	13	\N	\N	\N	1
491	5	2026-10-18	20261018	14	16	\N	13	\N	\N	\N	1
492	5	2026-10-17	20261017	26	21	\N	4	\N	\N	\N	1
493	5	2026-10-18	20261018	26	21	\N	4	\N	\N	\N	1
495	6	2026-10-19	3908	26	21	\N	4	\N	\N	\N	1
496	4	2026-10-19	3910	17	17	\N	13	\N	\N	Yarn Return	1
494	6	2026-10-19	3906,3907	15	14	\N	13	\N	\N	4700015813	1
498	6	2026-10-17	3902	15	14	\N	13	\N	\N	4700015813	1
499	5	2026-10-19	20261019	15	14	\N	13	\N	\N	\N	1
500	5	2026-10-19	20261019	14	16	\N	13	\N	\N	\N	1
501	5	2026-10-19	20261019	26	21	\N	4	\N	\N	\N	1
502	6	2026-10-19	3909	15	14	\N	13	\N	\N	4700015820	1
503	6	2026-10-19	3911	14	16	\N	13	\N	\N	Style#163255	1
504	6	2026-10-19	3913	17	17	\N	13	\N	\N	\N	1
505	4	2026-10-19	3912	17	17	\N	13	\N	\N	Yarn Return	1
506	4	2026-10-17	3903	\N	20	\N	13	\N	\N	Yarn Return	1
479	6	2026-10-16	1487	26	21	\N	4	\N	60	\N	1
463	6	2026-10-14	3895	26	21	\N	4	\N	60	\N	1
474	6	2026-10-15	3900	14	16	\N	1	\N	\N	\N	1
507	6	2026-10-21	3916	14	16	\N	13	\N	\N	Style# ZAYB	1
509	6	2026-10-20	3915	14	16	\N	13	\N	\N	\N	1
510	3	2026-10-20	2501,2502	14	16	\N	13	\N	\N	\N	1
511	3	2026-10-20	4700015905	15	14	\N	13	\N	\N	4700015905	1
513	5	2026-10-20	20261020	15	14	\N	13	\N	\N	\N	1
515	5	2026-10-20	20261020	17	17	\N	13	\N	\N	\N	1
512	3	2026-10-19	1253	17	17	\N	13	\N	\N	\N	1
497	3	2026-10-15	1251	17	17	\N	13	\N	\N	\N	1
508	6	2026-10-20	3914	15	14	\N	13	\N	\N	4700015820	1
516	5	2026-10-20	20261020	26	21	\N	4	\N	\N	\N	1
517	6	2026-10-21	1488	26	21	\N	4	\N	\N	\N	1
518	6	2026-10-21	3917,3918	14	16	\N	13	\N	\N	STYLE#163255,ZAYB	1
514	5	2026-10-20	20261020	14	16	\N	13	\N	\N	\N	1
520	5	2026-10-21	20261021	14	16	\N	13	\N	\N	\N	1
521	5	2026-10-21	20261021	15	14	\N	13	\N	\N	\N	1
523	5	2026-10-21	20261021	17	17	\N	13	\N	\N	\N	1
524	3	2026-10-21	WithoutChllan	26	21	\N	4	\N	\N	\N	1
522	5	2026-10-21	20261021	26	21	\N	4	\N	\N	\N	1
525	5	2026-10-22	20261022	15	14	\N	13	\N	\N	\N	1
526	5	2026-10-22	20261022	14	16	\N	13	\N	\N	\N	1
527	5	2026-10-22	20261022	26	21	\N	4	\N	\N	\N	1
528	5	2026-10-22	20261022	17	17	\N	13	\N	\N	\N	1
530	6	2026-10-22	3921	14	16	\N	13	\N	\N	STYLE#163253	1
529	6	2026-10-22	3920	15	14	\N	13	\N	\N	4700015820	1
531	6	2026-10-23	3922	15	14	\N	13	\N	\N	4700015820	1
519	6	2026-10-21	3919	15	14	\N	13	\N	\N	4700015820	1
532	5	2026-10-23	20261023	14	16	\N	13	\N	\N	\N	1
533	5	2026-10-23	20261023	15	14	\N	13	\N	\N	\N	1
534	5	2026-10-23	20261023	26	21	\N	4	\N	\N	\N	1
535	5	2026-10-23	20261023	17	17	\N	13	\N	\N	\N	1
536	3	2026-10-23	4700015966	15	14	\N	13	\N	\N	4700015966	1
537	6	2026-10-24	3924	15	14	\N	13	\N	\N	4700015905	1
538	3	2026-10-23	11864	17	17	\N	13	\N	\N	\N	1
539	3	2026-10-20	1281	17	17	\N	13	\N	\N	\N	1
540	3	2026-10-22	1282,1283	17	17	\N	13	\N	\N	1282,1283	1
543	3	2026-10-24	4023	14	16	\N	13	\N	\N	\N	1
544	5	2026-10-24	20261024	15	14	\N	13	\N	\N	\N	1
545	5	2026-10-25	20261025	14	16	\N	13	\N	\N	\N	1
546	5	2026-10-24	20261024	14	16	\N	13	\N	\N	\N	1
547	5	2026-10-25	202601025	15	14	\N	13	\N	\N	\N	1
548	5	2026-10-24	20261024	26	21	\N	4	\N	\N	\N	1
551	5	2026-10-24	20261024	17	17	\N	13	\N	\N	\N	1
552	5	2026-10-25	20261025	17	17	\N	13	\N	\N	\N	1
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
23	Bahnero Textiles 	Bahanero	1
24	Bhanero 	Bhanero 	1
25	Zahidjee Jee	Zahidjee Jee	1
26	Kasim	Kasim 	1
27	Mustaqim	Mustaqim 	1
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
53	12s	12s	1
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
68	34	2	25	1134.000	2	1
69	34	19	12	432.000	18	1
70	34	1	28	1270.080	20	1
72	35	1	100	4536.000	15	1
73	36	19	30	1080.000	18	1
74	37	19	28	1008.000	18	1
75	38	1	20	453.600	1	1
76	39	19	30	1080.000	18	1
77	40	2	25	1134.000	23	1
78	40	19	10	360.000	18	1
79	40	1	28	1270.080	20	1
81	41	13	42	1905.120	24	1
82	42	1	75	3402.000	4	1
83	43	13	5	226.800	15	1
84	44	2	32	1451.520	15	1
85	45	2	2	90.720	1	1
90	46	2	12	544.320	1	1
91	47	2	3	136.080	13	1
92	48	13	1	45.360	1	1
93	49	1	1	45.360	1	1
94	50	2	40	1814.400	15	1
95	51	2	2	90.720	1	1
96	52	2	1	18.000	1	1
97	53	14	1	45.360	1	1
98	54	13	89	4037.040	24	1
99	55	20	17	612.000	18	1
100	55	2	41	1838.180	1	1
101	55	1	42	1932.180	1	1
102	56	1	70	3175.200	15	1
103	57	20	9	324.000	18	1
104	57	2	35	1571.060	1	1
105	57	1	37	1651.410	1	1
106	58	20	9	324.000	18	1
107	58	2	36	1562.160	1	1
108	58	53	37	1642.050	1	1
109	59	20	9	324.000	18	1
110	59	2	35	1562.160	1	1
111	59	53	37	1642.050	1	1
112	60	20	28	1008.000	18	1
113	60	2	35	1562.170	1	1
114	60	53	37	1642.060	1	1
115	61	20	9	324.000	18	1
116	61	2	35	1562.160	1	1
117	61	53	37	1642.050	1	1
118	62	2	60	2721.600	24	1
119	63	2	106	4808.160	24	1
120	64	19	25	900.000	18	1
121	65	19	25	900.000	18	1
122	66	1	3	136.080	4	1
123	67	13	30	1360.800	15	1
124	68	15	113	5125.680	14	1
125	69	2	50	2268.000	15	1
126	70	2	50	2268.000	15	1
127	71	20	11	396.000	18	1
128	71	2	32	1451.110	1	1
129	71	1	41	1838.080	1	1
130	72	20	33	693.000	18	1
131	72	2	77	3458.840	1	1
132	73	20	10	360.000	18	1
133	73	2	40	1778.160	1	1
134	73	1	50	2252.340	1	1
135	74	1	97	4381.190	1	1
136	75	1	15	680.400	14	1
137	76	13	10	453.600	19	1
138	76	1	7	317.520	1	1
139	76	19	4	144.000	18	1
140	77	19	25	900.000	18	1
141	78	19	20	720.000	18	1
142	79	20	18	594.000	18	1
143	79	2	38	1688.100	1	1
144	79	1	49	2213.150	1	1
145	80	13	13	589.680	19	1
146	80	1	5	226.800	26	1
157	83	13	2	90.720	24	1
158	83	13	1	8.000	24	1
159	84	20	22	726.000	18	1
160	84	2	34	1542.240	1	1
161	84	1	45	2020.520	1	1
162	81	13	2	90.720	21	1
163	81	2	5	226.800	21	1
164	81	1	6	272.160	26	1
165	81	13	2	90.720	21	1
166	81	1	6	272.160	26	1
167	81	2	5	226.800	21	1
168	81	1	1	45.360	26	1
169	82	1	11	498.960	26	1
170	82	1	10	453.600	27	1
171	82	19	8	288.000	18	1
173	85	1	7	317.520	14	1
175	86	2	100	4536.000	24	1
176	87	13	25	1134.000	24	1
177	88	20	11	363.000	18	1
178	88	2	34	1542.240	1	1
179	88	1	45	2020.020	1	1
180	89	2	5	226.800	21	1
181	89	2	3	49.900	21	1
182	90	1	100	4536.000	14	1
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
21	2026-08-05	14	submitted	Iftikhar 	2026-08-11 07:39:31.106192	\N	2026-08-11 07:39:31.106192	t	196	2026-08-11 07:41:22.139	47*15011	1
33	2026-08-29	13	submitted	Iftikhar Ahmed	2026-08-29 05:43:37.982683	\N	2026-08-29 05:43:37.982683	t	290	2026-08-29 07:38:59.635	170468	1
22	2026-08-18	17	submitted	Iftikhar Ahmed	2026-08-19 11:31:08.766439	\N	2026-08-19 11:31:08.766439	t	239	2026-08-20 09:04:20.032	1483	1
23	2026-08-18	17	submitted	Iftikhar Ahmed	2026-08-19 11:32:20.90415	\N	2026-08-19 11:32:20.90415	t	240	2026-08-20 09:06:41.514	1484	1
24	2026-08-18	17	submitted	Iftikhar Ahmed	2026-08-19 11:33:54.607283	Iftikhar Ahmed	2026-08-19 11:35:52.385	t	241	2026-08-20 09:08:57.154	1485	1
34	2026-08-31	13	submitted	Iftikhar Ahmed	2026-08-31 12:07:13.858442	\N	2026-08-31 12:07:13.858442	t	297	2026-08-31 12:30:19.218	170527	1
25	2026-08-20	17	submitted	Iftikhar Ahmed	2026-08-20 12:28:44.161241	Iftikhar Ahmed	2026-08-21 04:59:13.033	t	245	2026-08-21 07:06:51.4	1489	1
26	2026-08-21	17	submitted	Iftikhar Ahmed	2026-08-21 12:34:23.886984	\N	2026-08-21 12:34:23.886984	t	253	2026-08-22 06:47:15.621	1492	1
27	2026-08-21	17	submitted	Iftikhar Ahmed	2026-08-21 12:35:09.127188	\N	2026-08-21 12:35:09.127188	t	254	2026-08-22 06:48:13.848	1493	1
35	2026-08-31	16	submitted	Iftikhar Ahmed	2026-09-01 06:26:25.690723	Iftikhar Ahmed	2026-09-01 06:27:14.158	t	300	2026-09-01 06:53:28.323	1253	1
36	2026-09-02	16	submitted	Iftikhar Ahmed	2026-09-02 08:03:08.437463	\N	2026-09-02 08:03:08.437463	t	305	2026-09-03 06:37:09.902	2228	1
37	2026-09-02	16	submitted	Iftikhar Ahmed	2026-09-02 09:25:43.627092	\N	2026-09-02 09:25:43.627092	t	305	2026-09-03 06:37:09.902	2223	1
20	2026-08-01	16	submitted	Hsn	2026-08-11 07:04:47.713807	\N	2026-08-11 07:04:47.713807	t	\N	2026-08-11 07:07:00.433	16237	1
38	2026-09-03	15	submitted	Iftikhar Ahmed	2026-09-03 07:00:51.769329	\N	2026-09-03 07:00:51.769329	t	313	2026-09-04 06:38:38.131	Gp2609.28	1
39	2026-09-03	16	submitted	Iftikhar Ahmed	2026-09-03 11:10:06.367899	\N	2026-09-03 11:10:06.367899	t	314	2026-09-04 06:39:57.596	2236	1
40	2026-09-03	13	submitted	Iftikhar Ahmed	2026-09-03 11:54:10.067337	\N	2026-09-03 11:54:10.067337	t	315	2026-09-04 06:41:38.088	170641	1
41	2026-09-02	17	submitted	Iftikhar Ahmed	2026-09-03 13:53:18.708906	Iftikhar Ahmed	2026-09-03 13:53:54.26	t	316	2026-09-04 06:43:21.318	1434	1
42	2026-09-05	16	submitted	Iftikhar Ahmed	2026-09-05 11:35:04.526294	\N	2026-09-05 11:35:04.526294	t	328	2026-09-07 07:26:00.546	1368512	1
30	2026-08-27	15	submitted	Iftikhar Ahmed	2026-08-27 10:05:46.591103	\N	2026-08-27 10:05:46.591103	t	\N	2026-08-28 07:09:38.203	762	1
43	2026-09-07	16	submitted	Iftikhar Ahmed	2026-09-07 13:28:58.502442	\N	2026-09-07 13:28:58.502442	t	336	2026-09-08 06:51:46.215	1424	1
44	2026-09-07	16	submitted	Iftikhar Ahmed	2026-09-07 13:29:42.159342	\N	2026-09-07 13:29:42.159342	t	336	2026-09-08 06:51:46.215	1425	1
54	2026-09-10	16	submitted	Iftikhar Ahmed	2026-09-10 13:23:56.253548	\N	2026-09-10 13:23:56.253548	t	351	2026-09-11 06:51:23.757	24345	1
55	2026-09-10	14	submitted	Iftikhar Ahmed	2026-09-11 07:04:56.748426	\N	2026-09-11 07:04:56.748426	t	352	2026-09-11 11:34:39.699	47*15481	1
50	2026-09-08	16	submitted	Iftikhar Ahmed	2026-09-08 12:33:01.636511	\N	2026-09-08 12:33:01.636511	t	342	2026-09-09 10:01:40.298	1435	1
51	2026-09-08	23	submitted	Iftikhar Ahmed	2026-09-10 05:56:19.306659	\N	2026-09-10 05:56:19.306659	t	343	2026-09-10 09:33:52.294	1668	1
52	2026-09-08	23	submitted	Iftikhar Ahmed	2026-09-10 05:57:45.541091	\N	2026-09-10 05:57:45.541091	t	343	2026-09-10 09:33:52.294	11456	1
45	2026-09-08	22	submitted	Hassan Imam	2026-09-08 09:37:49.527468	\N	2026-09-08 09:37:49.527468	t	348	2026-09-10 11:25:37.336	20260908	1
46	2026-09-08	22	submitted	Hassan Imam	2026-09-08 09:38:53.115622	Hassan Imam	2026-09-08 09:44:49.358	t	348	2026-09-10 11:25:37.336	20260908	1
47	2026-09-08	22	submitted	Hassan Imam	2026-09-08 09:39:41.118961	Hassan Imam	2026-09-08 09:44:56.895	t	348	2026-09-10 11:25:37.336	20260908	1
48	2026-09-08	22	submitted	Hassan Imam	2026-09-08 09:42:40.976651	Hassan Imam	2026-09-08 09:45:03.612	t	348	2026-09-10 11:25:37.336	20260908	1
49	2026-09-08	22	submitted	Hassan Imam	2026-09-08 09:42:57.947383	Hassan Imam	2026-09-08 09:45:11.036	t	348	2026-09-10 11:25:37.336	20260908	1
53	2026-09-08	22	submitted	Hassan Imam	2026-09-10 11:22:45.14304	\N	2026-09-10 11:22:45.14304	t	348	2026-09-10 11:25:37.336	20260908	1
56	2026-09-11	16	submitted	Iftikhar Ahmed	2026-09-11 12:39:06.766088	\N	2026-09-11 12:39:06.766088	t	355	2026-09-12 06:39:49.182	1531	1
57	2026-09-12	14	submitted	Iftikhar Ahmed	2026-09-14 06:18:46.822321	\N	2026-09-14 06:18:46.822321	t	363	2026-09-14 08:24:25.77	47*15497	1
58	2026-09-17	14	submitted	Iftikhar Ahmed	2026-09-18 07:33:04.029692	\N	2026-09-18 07:33:04.029692	t	375	2026-09-18 12:01:47.901	47*15553	1
59	2026-09-19	14	submitted	Iftikhar Ahmed	2026-09-19 14:00:31.903038	\N	2026-09-19 14:00:31.903038	t	382	2026-09-21 08:12:21.383	47*15573	1
60	2026-09-21	14	submitted	Iftikhar Ahmed	2026-09-22 06:21:11.753664	\N	2026-09-22 06:21:11.753664	t	391	2026-09-23 06:43:54.865	47*15594	1
61	2026-09-23	14	submitted	Iftikhar Ahmed	2026-09-24 05:45:38.386827	\N	2026-09-24 05:45:38.386827	t	395	2026-09-24 07:21:00.765	47*15635	1
62	2026-09-24	16	submitted	Iftikhar Ahmed	2026-09-24 13:51:27.903716	\N	2026-09-24 13:51:27.903716	t	401	2026-09-25 09:05:49.828	381	1
63	2026-09-28	16	submitted	Iftikhar Ahmed	2026-09-28 13:01:06.052076	\N	2026-09-28 13:01:06.052076	t	415	2026-09-30 06:36:08.075	389	1
64	2026-10-02	16	submitted	Iftikhar Ahmed	2026-10-02 11:09:07.244369	\N	2026-10-02 11:09:07.244369	t	424	2026-10-03 07:50:33.679	2241	1
65	2026-10-02	16	submitted	Iftikhar Ahmed	2026-10-02 12:57:52.160545	\N	2026-10-02 12:57:52.160545	t	424	2026-10-03 07:50:33.679	2240	1
66	2026-10-03	16	submitted	Iftikhar Ahmed	2026-10-03 14:14:18.699695	\N	2026-10-03 14:14:18.699695	t	430	2026-10-06 10:21:48.015	6353	1
80	2026-10-20	17	submitted	Iftikhar Ahmed	2026-10-23 12:19:10.109766	\N	2026-10-23 12:19:10.109766	t	539	2026-10-24 09:32:37.313	1281	1
67	2026-10-06	16	submitted	Iftikhar Ahmed	2026-10-06 12:30:49.130095	\N	2026-10-06 12:30:49.130095	t	431	2026-10-07 06:48:16.962	2071	1
68	2026-10-06	16	submitted	Iftikhar Ahmed	2026-10-06 14:41:11.045412	\N	2026-10-06 14:41:11.045412	t	431	2026-10-07 06:48:16.962	6520013510	1
69	2026-10-07	16	submitted	Iftikhar Ahmed	2026-10-07 11:05:59.693165	\N	2026-10-07 11:05:59.693165	t	437	2026-10-09 07:15:18.635	2098	1
81	2026-10-22	17	submitted	Iftikhar Ahmed	2026-10-23 12:24:03.793872	Khurram Hassan	2026-10-24 09:21:58.325	t	540	2026-10-24 10:09:26.692	1282	1
82	2026-10-22	17	submitted	Iftikhar Ahmed	2026-10-23 12:30:52.493284	Khurram Hassan	2026-10-24 09:23:46.466	t	540	2026-10-24 10:09:26.692	1283	1
70	2026-10-10	16	submitted	Iftikhar Ahmed	2026-10-10 10:13:29.094851	\N	2026-10-10 10:13:29.094851	t	447	2026-10-12 07:21:42.603	0262102	1
71	2026-10-10	14	submitted	Iftikhar Ahmed	2026-10-10 16:08:50.818446	\N	2026-10-10 16:08:50.818446	t	448	2026-10-12 07:23:58.118	47*15790	1
85	2026-10-24	16	submitted	Iftikhar Ahmed	2026-10-24 09:36:04.323358	Iftikhar Ahmed	2026-10-24 09:48:34.08	t	543	2026-10-24 10:35:37.892	4023	1
86	2026-10-26	16	submitted	Iftikhar Ahmed	2026-10-26 12:56:30.692359	Iftikhar Ahmed	2026-10-26 12:56:51.093	f	\N	\N	1240	1
72	2026-10-14	14	submitted	Iftikhar Ahmed	2026-10-14 06:25:17.096282	\N	2026-10-14 06:25:17.096282	t	464	2026-10-14 11:23:47.372	47*15820	1
73	2026-10-14	14	submitted	Iftikhar Ahmed	2026-10-14 07:33:38.891388	\N	2026-10-14 07:33:38.891388	t	464	2026-10-14 11:23:47.372	47*15813	1
87	2026-10-26	16	submitted	Iftikhar Ahmed	2026-10-26 12:57:33.137804	\N	2026-10-26 12:57:33.137804	f	\N	\N	1241	1
74	2026-10-14	14	submitted	Iftikhar Ahmed	2026-10-14 13:45:57.7511	\N	2026-10-14 13:45:57.7511	t	465	2026-10-15 06:54:00.333	47*15820	1
88	2026-10-26	14	submitted	Iftikhar Ahmed	2026-10-26 14:33:20.099315	\N	2026-10-26 14:33:20.099315	f	\N	\N	47*16004	1
75	2026-10-17	16	submitted	Iftikhar Ahmed	2026-10-17 10:12:56.08508	\N	2026-10-17 10:12:56.08508	t	485	2026-10-17 10:42:54.602	4253	1
89	2026-10-26	17	submitted	Iftikhar Ahmed	2026-10-26 14:36:51.825696	\N	2026-10-26 14:36:51.825696	f	\N	\N	11897	1
90	2026-10-26	16	submitted	Iftikhar Ahmed	2026-10-26 16:34:35.819359	\N	2026-10-26 16:34:35.819359	f	\N	\N	6520013682	1
77	2026-10-20	16	submitted	Iftikhar Ahmed	2026-10-20 09:45:16.096336	\N	2026-10-20 09:45:16.096336	t	510	2026-10-21 06:32:58.506	2501	1
78	2026-10-20	16	submitted	Iftikhar Ahmed	2026-10-20 11:23:03.481465	\N	2026-10-20 11:23:03.481465	t	510	2026-10-21 06:32:58.506	2502	1
79	2026-10-20	14	submitted	Iftikhar Ahmed	2026-10-20 14:53:45.268204	\N	2026-10-20 14:53:45.268204	t	511	2026-10-21 06:36:01.707	47*15905	1
76	2026-10-19	17	submitted	Iftikhar Ahmed	2026-10-20 09:44:14.495053	\N	2026-10-20 09:44:14.495053	t	512	2026-10-21 06:39:22.133	1253	1
84	2026-10-24	14	submitted	Iftikhar Ahmed	2026-10-24 06:38:20.053276	\N	2026-10-24 06:38:20.053276	t	536	2026-10-24 09:11:37.777	47*15966	1
83	2026-10-23	17	submitted	Iftikhar Ahmed	2026-10-23 12:33:21.3633	\N	2026-10-23 12:33:21.3633	t	538	2026-10-24 09:25:48.19	11864	1
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
26	3-Fleece (30/1 HG)	3-Fleece (30/1 HG)	\N	6002.9000	1
27	3-Fleece (30/1 CTN)	3-Fleece (30/1 CTN)	\N	6002.9000	1
28	3-Fleece (30/1 CVC)	3-Fleece (30/1 CVC)	\N	6002.9000	1
30	Single Jersey (CTN)	SJ-CTN	\N	\t6002.9000	1
31	Single Jersey (CVC)	SJ-CVC	\N	\t6002.9000	1
32	Single Jersey (HG)	SJ-HG	\N	\t6002.9000	1
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

SELECT pg_catalog.setval('public.attendance_id_seq', 19898, true);


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

SELECT pg_catalog.setval('public.daily_delivery_id_seq', 211, true);


--
-- Name: daily_production_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_production_detail_id_seq', 6111, true);


--
-- Name: daily_production_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_production_header_id_seq', 887, true);


--
-- Name: department_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.department_master_id_seq', 4, true);


--
-- Name: email_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.email_templates_id_seq', 1, false);


--
-- Name: employee_loan_deductions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.employee_loan_deductions_id_seq', 1, false);


--
-- Name: employee_loans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.employee_loans_id_seq', 2, true);


--
-- Name: fabric_type_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.fabric_type_master_id_seq', 16, true);


--
-- Name: factory_maintenance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.factory_maintenance_id_seq', 4, true);


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

SELECT pg_catalog.setval('public.invoice_id_seq', 270, true);


--
-- Name: invoice_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invoice_item_id_seq', 93, true);


--
-- Name: invoice_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invoice_payment_id_seq', 21, true);


--
-- Name: invoice_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invoice_transaction_id_seq', 87, true);


--
-- Name: job_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.job_master_id_seq', 26, true);


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

SELECT pg_catalog.setval('public.machine_history_id_seq', 14, true);


--
-- Name: machine_maintenance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.machine_maintenance_id_seq', 9, true);


--
-- Name: machine_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.machine_master_id_seq', 29, true);


--
-- Name: machine_operator_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.machine_operator_master_id_seq', 48, true);


--
-- Name: oauth_providers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.oauth_providers_id_seq', 3, true);


--
-- Name: operator_advances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operator_advances_id_seq', 74, true);


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

SELECT pg_catalog.setval('public.party_master_id_seq', 23, true);


--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.password_reset_tokens_id_seq', 1, false);


--
-- Name: plausibility_baseline_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.plausibility_baseline_id_seq', 23807, true);


--
-- Name: plausibility_feedback_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.plausibility_feedback_id_seq', 121, true);


--
-- Name: role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.role_id_seq', 9, true);


--
-- Name: salary_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.salary_detail_id_seq', 80, true);


--
-- Name: salary_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.salary_header_id_seq', 5, true);


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

SELECT pg_catalog.setval('public.transaction_detail_id_seq', 1802, true);


--
-- Name: transaction_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transaction_header_id_seq', 552, true);


--
-- Name: transaction_type_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transaction_type_master_id_seq', 9, true);


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

SELECT pg_catalog.setval('public.yarn_brand_master_id_seq', 27, true);


--
-- Name: yarn_count_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_count_master_id_seq', 53, true);


--
-- Name: yarn_receipt_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_receipt_detail_id_seq', 182, true);


--
-- Name: yarn_receipt_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_receipt_header_id_seq', 90, true);


--
-- Name: yarn_type_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_type_master_id_seq', 32, true);


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
-- Name: employee_loan_deductions employee_loan_deductions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_loan_deductions
    ADD CONSTRAINT employee_loan_deductions_pkey PRIMARY KEY (id);


--
-- Name: employee_loans employee_loans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_loans
    ADD CONSTRAINT employee_loans_pkey PRIMARY KEY (id);


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
-- Name: employee_loan_deductions_employee_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX employee_loan_deductions_employee_idx ON public.employee_loan_deductions USING btree (employee_id);


--
-- Name: employee_loan_deductions_header_employee_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX employee_loan_deductions_header_employee_unique ON public.employee_loan_deductions USING btree (header_id, employee_id);


--
-- Name: employee_loans_employee_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX employee_loans_employee_date_idx ON public.employee_loans USING btree (employee_id, date);


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
-- Name: employee_loan_deductions employee_loan_deductions_employee_id_employee_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_loan_deductions
    ADD CONSTRAINT employee_loan_deductions_employee_id_employee_master_id_fk FOREIGN KEY (employee_id) REFERENCES public.employee_master(id);


--
-- Name: employee_loan_deductions employee_loan_deductions_header_id_salary_header_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_loan_deductions
    ADD CONSTRAINT employee_loan_deductions_header_id_salary_header_id_fk FOREIGN KEY (header_id) REFERENCES public.salary_header(id) ON DELETE CASCADE;


--
-- Name: employee_loan_deductions employee_loan_deductions_tenant_id_tenants_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_loan_deductions
    ADD CONSTRAINT employee_loan_deductions_tenant_id_tenants_id_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: employee_loans employee_loans_employee_id_employee_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_loans
    ADD CONSTRAINT employee_loans_employee_id_employee_master_id_fk FOREIGN KEY (employee_id) REFERENCES public.employee_master(id);


--
-- Name: employee_loans employee_loans_tenant_id_tenants_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_loans
    ADD CONSTRAINT employee_loans_tenant_id_tenants_id_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


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

\unrestrict zSXcwRdi6AEpfcNYbB0IW0rLqTvoOof6lfKFto88DK1pX6UptIDkTMoUMiBe6cd

