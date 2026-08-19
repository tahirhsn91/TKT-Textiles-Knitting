--
-- PostgreSQL database dump
--

\restrict Ay0XVDASSl5UgwyE6icWY9IqHNp1aSDYk2NaeS7m9zB0dzfCWAnlgXdpMu2bQjt

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
    updated_at timestamp without time zone DEFAULT now() NOT NULL
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
    updated_at timestamp without time zone DEFAULT now() NOT NULL
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
    enabled boolean DEFAULT true NOT NULL
);


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
    code text NOT NULL
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
-- Name: employee_advances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employee_advances (
    id integer NOT NULL,
    employee_id integer NOT NULL,
    date date NOT NULL,
    amount numeric NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT now()
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
    active boolean DEFAULT true NOT NULL
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
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: employee_salary_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employee_salary_settings (
    id integer NOT NULL,
    employee_id integer NOT NULL,
    base_daily_wage numeric DEFAULT 0 NOT NULL
);


--
-- Name: fabric_type_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fabric_type_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL
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
    origin text DEFAULT 'fbr'::text
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
    sale_type text DEFAULT 'Goods at standard rate (default)'::text NOT NULL
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
    created_at timestamp without time zone DEFAULT now()
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
    transaction_header_id integer NOT NULL
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
    party_id integer
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
    code text NOT NULL
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
    sinker_brand text DEFAULT 'Kohala'::text
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
    credit_days integer DEFAULT 0 NOT NULL
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
    computed_at timestamp without time zone DEFAULT now() NOT NULL
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
    created_at timestamp without time zone DEFAULT now() NOT NULL
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
    created_at timestamp without time zone DEFAULT now() NOT NULL
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
    payable_salary numeric(10,2) DEFAULT '0'::numeric NOT NULL
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
    updated_at timestamp without time zone DEFAULT now()
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
    uom_id integer
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
    reference text
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
    action text
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
-- Name: uom_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.uom_master (
    id integer NOT NULL,
    name text NOT NULL,
    abbreviation text NOT NULL
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
-- Name: yarn_brand_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.yarn_brand_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL
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
    count text NOT NULL
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
    hs_code text
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
-- Name: app_user id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_user ALTER COLUMN id SET DEFAULT nextval('public.app_user_id_seq'::regclass);


--
-- Name: company_info_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_info_master ALTER COLUMN id SET DEFAULT nextval('public.company_info_master_id_seq'::regclass);


--
-- Name: configuration id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuration ALTER COLUMN id SET DEFAULT nextval('public.configuration_id_seq'::regclass);


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
-- Name: party_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.party_master ALTER COLUMN id SET DEFAULT nextval('public.party_master_id_seq'::regclass);


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
-- Name: uom_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uom_master ALTER COLUMN id SET DEFAULT nextval('public.uom_master_id_seq'::regclass);


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
\.


--
-- Data for Name: app_user; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.app_user (id, username, display_name, password_hash, role_id, employee_id, is_active, created_at, updated_at) FROM stdin;
1	admin	Administrator	$argon2id$v=19$m=65536,t=3,p=4$a1CQL2gbg+KObhCtXyWnKw$VvVr3t3pPUEpK5Bv4Qbe9dOKUfZ87OGCrzAWXt3Ac8o	1	\N	t	2026-08-14 10:51:30.060555	2026-08-14 10:51:30.060555
4	hassanimam	Hassan Imam	$argon2id$v=19$m=65536,t=3,p=4$lIPw0HuW5aYPfcKvovWglA$uTvtFYf2bPT/nK7P+4xat9CaZ9X40lXTEHXAwLydVTA	2	\N	t	2026-08-14 10:58:13.371543	2026-08-14 10:58:13.371543
2	khurranhassan	Khurram Hassan	$argon2id$v=19$m=65536,t=3,p=4$b/w2NGtIlSCdBiEPSpQJtg$tLnKPABoyptuY32k0HU0KHkWwGrI3p9n3sia7+NdvJ4	2	\N	f	2026-08-14 10:56:53.242172	2026-08-14 10:58:56.538
5	khurramhassan	Khurram Hassan	$argon2id$v=19$m=65536,t=3,p=4$J9kPaVtTsAwfsDv9VVulAg$+Zmc0plbzRftGM6VqRGq9lkPVU+emmhpq0DMP0WqMBY	2	\N	t	2026-08-14 10:59:19.452899	2026-08-14 10:59:19.452899
6	tahirhassan	Tahir Hassan	$argon2id$v=19$m=65536,t=3,p=4$a17sl2Znzn5HUIfBkSEY/g$nmHLMcaU7XtN+JmqsWDhU5Q5guak87FfUJEiG4PmtXo	1	\N	t	2026-08-14 11:01:50.16956	2026-08-14 11:01:50.16956
3	iftikhar	Iftikhar Ahmed	$argon2id$v=19$m=65536,t=3,p=4$HnNB8pBD8jSUEb5yqsvCJQ$VTot2bTY0zOAH87K0Pv4x8BXxF7C/+zbRz5oisjsU0s	3	10	t	2026-08-14 10:57:48.772162	2026-08-17 06:29:47.322
\.


--
-- Data for Name: company_info_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.company_info_master (id, name, ntn_cnic, province, address, fbr_sandbox_token, fbr_production_token, is_default, created_at, updated_at) FROM stdin;
1	TKT TEXTILES	4636080	Sindh	SHADE # 1-A, PLOT NO.L-39/1, BLOCK # 22, F.B. INDUSTRIAL AREA	0df2cdcf-d19a-34da-abf4-ca470c74a565	a20c225b-60e1-3d44-9966-41007b99d358	t	2026-08-12 17:58:06.278128	2026-08-12 17:58:06.278128
\.


--
-- Data for Name: configuration; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.configuration (id, name, code, description, enabled) FROM stdin;
1	Reconciled lock	0001	used to enable/disable Reconciliation lock in daily operations	t
2	FBR DI Sandbox	0002	used to enable/disable FBR Digital Invoicing sandbox environment; when enabled invoices post to sandbox, when disabled they post to production	t
3	Allow Backdated Invoices	0003	when enabled, shows the manual "Create Backdated Invoice" tool to record invoices generated from another system	f
\.


--
-- Data for Name: daily_delivery; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_delivery (id, delivery_date, party_id, challan_no, sl, gsm, quantity, net_weight, status, created_by, created_at, updated_by, updated_at, reconciled, reconciled_transaction_id, reconciled_at, yarn_type_id) FROM stdin;
24	2026-08-10	13	3754	960+720+370	250	42	1116.150	submitted	Iftikhar 	2026-08-10 07:34:04.360986	\N	2026-08-10 07:34:04.360986	t	190	2026-08-10 10:30:29.442	20
27	2026-08-10	14	D-3757	940+640+384	345	27	759.350	submitted	Iftikhar 	2026-08-10 07:36:55.958949	\N	2026-08-10 07:36:55.958949	t	191	2026-08-10 10:36:36.152	20
25	2026-08-10	14	3755	940+662+395	345	36	1011.850	submitted	Iftikhar 	2026-08-10 07:34:59.665056	\N	2026-08-10 07:34:59.665056	t	191	2026-08-10 10:36:36.152	20
26	2026-08-10	14	3756	940+662+395	345	49	1391.000	submitted	Iftikhar 	2026-08-10 07:35:52.138509	\N	2026-08-10 07:35:52.138509	t	191	2026-08-10 10:36:36.152	20
7	2026-08-01	13	3735	960+720+370	250	27	694.750	submitted	Iftikhar 	2026-08-06 12:19:38.742471	\N	2026-08-06 12:19:38.742471	t	161	2026-08-07 12:37:27.219	20
8	2026-08-03	13	3736	960+720+370	250	47	1233.900	submitted	Iftikhar 	2026-08-06 12:21:22.753913	\N	2026-08-06 12:21:22.753913	t	162	2026-08-07 12:41:07.182	20
17	2026-08-03	15	3737	1020+740+410	\N	37	990.450	submitted	Iftikhar 	2026-08-06 13:28:50.974992	\N	2026-08-06 13:28:50.974992	t	163	2026-08-07 12:47:22.057	20
9	2026-08-04	13	3738	960+720+370	250	20	498.150	submitted	Iftikhar 	2026-08-06 12:22:22.726969	\N	2026-08-06 12:22:22.726969	t	170	2026-08-08 07:01:16.924	20
18	2026-08-04	20	3739	960+670+400	\N	2	39.700	submitted	Iftikhar 	2026-08-06 13:30:30.629482	\N	2026-08-06 13:30:30.629482	t	171	2026-08-08 07:02:25.572	20
11	2026-08-04	16	3740	820	\N	1	5.300	submitted	Iftikhar 	2026-08-06 13:13:02.850451	\N	2026-08-06 13:13:02.850451	t	172	2026-08-08 07:06:33.654	22
12	2026-08-04	16	3740	1160	\N	1	9.500	submitted	Iftikhar 	2026-08-06 13:14:18.421923	\N	2026-08-06 13:14:18.421923	t	172	2026-08-08 07:06:33.654	24
14	2026-08-04	16	3742	1060+730+410	\N	14	401.700	submitted	Iftikhar 	2026-08-06 13:17:32.154431	\N	2026-08-06 13:17:32.154431	t	172	2026-08-08 07:06:33.654	20
16	2026-08-04	16	3742	1160	\N	4	100.050	submitted	Iftikhar 	2026-08-06 13:19:53.154209	\N	2026-08-06 13:19:53.154209	t	172	2026-08-08 07:06:33.654	24
13	2026-08-04	16	3741	1160	\N	19	561.250	submitted	Iftikhar 	2026-08-06 13:15:38.784798	Iftikhar 	2026-08-06 13:20:56.385	t	172	2026-08-08 07:06:33.654	24
15	2026-08-04	16	3742	820	140	1	11.800	submitted	Iftikhar 	2026-08-06 13:18:53.501896	Iftikhar 	2026-08-06 13:21:15.74	t	172	2026-08-08 07:06:33.654	22
19	2026-08-04	17	3743	1050+700+405	210	18	439.850	submitted	Iftikhar 	2026-08-06 13:32:33.689048	\N	2026-08-06 13:32:33.689048	t	173	2026-08-08 07:07:55.163	20
3	2026-08-05	14	3744	940+662+395	250	58	1721.300	submitted	Iftikhar 	2026-08-06 10:11:17.157237	\N	2026-08-06 10:11:17.157237	t	174	2026-08-08 07:09:33.234	20
4	2026-08-05	14	3745	940+662+395	250	59	1717.850	submitted	Iftikhar 	2026-08-06 10:12:28.906007	\N	2026-08-06 10:12:28.906007	t	174	2026-08-08 07:09:33.234	20
10	2026-08-05	13	3746	960+720+370	250	15	384.800	submitted	Iftikhar 	2026-08-06 12:23:52.485668	\N	2026-08-06 12:23:52.485668	t	175	2026-08-08 07:12:14.027	20
5	2026-08-06	14	3747	940+662+395	250	50	1422.800	submitted	Iftikhar 	2026-08-06 10:13:52.292123	Iftikhar 	2026-08-06 13:23:26.528	t	176	2026-08-08 07:13:44.041	20
6	2026-08-06	14	3748	940+662+395	250	59	1663.250	submitted	Iftikhar 	2026-08-06 10:14:46.992303	Iftikhar 	2026-08-06 13:23:55.892	t	176	2026-08-08 07:13:44.041	20
2	2026-08-06	13	3749	960+720+370	245	22	599.300	submitted	Iftikhar 	2026-08-06 09:37:19.084532	Iftikhar 	2026-08-06 12:17:49.83	t	177	2026-08-08 07:15:21.916	20
20	2026-08-07	13	3750	960+720+370	250	25	672.600	submitted	Iftikhar 	2026-08-07 10:24:04.049319	\N	2026-08-07 10:24:04.049319	t	178	2026-08-08 07:16:19.208	20
21	2026-08-07	14	3751	940+640+384	342	52	1514.900	submitted	Iftikhar 	2026-08-07 11:07:58.052085	\N	2026-08-07 11:07:58.052085	t	179	2026-08-08 07:18:48.911	20
22	2026-08-07	14	3752	940+640+384	245	52	1518.400	submitted	Iftikhar 	2026-08-07 15:37:46.719266	\N	2026-08-07 15:37:46.719266	t	179	2026-08-08 07:18:48.911	20
23	2026-08-08	13	3753	960+720+370	250	25	671.800	submitted	Iftikhar 	2026-08-08 06:24:28.201474	\N	2026-08-08 06:24:28.201474	t	180	2026-08-08 07:19:38.526	20
28	2026-08-10	16	3758	1160	245	6	150.600	submitted	Iftikhar 	2026-08-10 14:00:45.636968	\N	2026-08-10 14:00:45.636968	t	199	2026-08-11 08:09:50.771	24
31	2026-08-11	16	3761	\N	\N	26	718.900	submitted	Iftikhar 	2026-08-11 11:10:58.071828	Tahir Hassan	2026-08-15 10:59:53.434	t	216	2026-08-15 11:09:20.759	24
32	2026-08-11	16	3762	1060+730+410	\N	10	270.650	submitted	Iftikhar 	2026-08-11 11:11:52.777587	Tahir Hassan	2026-08-15 10:59:57.537	t	217	2026-08-15 11:10:37.621	20
33	2026-08-13	14	3767	940+640+384	\N	56	1549.050	submitted	Iftikhar 	2026-08-13 08:03:37.872534	\N	2026-08-13 08:03:37.872534	t	218	2026-08-15 11:12:06.539	20
29	2026-08-11	13	3759	960+720+370	250	47	1137.500	submitted	Iftikhar 	2026-08-11 08:02:53.830219	\N	2026-08-11 08:02:53.830219	t	209	2026-08-13 09:39:39.487	20
41	2026-08-18	16	3774	820	140	1	10.000	submitted	Iftikhar Ahmed	2026-08-18 11:55:08.347932	\N	2026-08-18 11:55:08.347932	t	234	2026-08-19 07:36:58.451	22
42	2026-08-18	16	3774	820	\N	2	42.100	submitted	Iftikhar Ahmed	2026-08-18 11:55:59.775651	\N	2026-08-18 11:55:59.775651	t	235	2026-08-19 07:38:52.137	23
34	2026-08-13	14	3768	940+640+384	\N	50	1377.550	submitted	Iftikhar 	2026-08-13 08:04:21.240042	Tahir Hassan	2026-08-15 11:00:42.768	t	218	2026-08-15 11:12:06.539	20
30	2026-08-11	16	3760	1060+730+410	\N	60	1564.400	submitted	Iftikhar 	2026-08-11 11:09:58.933201	Iftikhar 	2026-08-12 10:27:12.968	t	215	2026-08-15 11:08:24.116	20
35	2026-08-13	16	3769	1160	\N	5	117.000	submitted	Iftikhar 	2026-08-13 10:17:45.783406	\N	2026-08-13 10:17:45.783406	t	219	2026-08-15 11:13:40.804	24
36	2026-08-13	16	3770	820	145	1	5.200	submitted	Iftikhar 	2026-08-13 10:18:47.014887	Tahir Hassan	2026-08-15 11:01:03.094	t	220	2026-08-15 11:15:00.318	22
37	2026-08-13	16	3770	1000+740+380	245	1	24.800	submitted	Iftikhar 	2026-08-13 10:19:44.871288	Tahir Hassan	2026-08-15 11:01:09.166	t	220	2026-08-15 11:15:00.318	20
38	2026-08-17	14	3771	940+640+384	340	49	1388.750	submitted	Iftikhar Ahmed	2026-08-17 07:19:50.870723	\N	2026-08-17 07:19:50.870723	t	224	2026-08-17 11:01:57.708	20
39	2026-08-17	14	3772	940+640+384	340	51	1429.200	submitted	Iftikhar Ahmed	2026-08-17 07:20:44.956228	\N	2026-08-17 07:20:44.956228	t	224	2026-08-17 11:01:57.708	20
40	2026-08-18	16	3774	1000+700+385	\N	9	243.300	submitted	Iftikhar Ahmed	2026-08-18 11:54:13.546052	\N	2026-08-18 11:54:13.546052	t	233	2026-08-19 07:33:50.419	20
\.


--
-- Data for Name: daily_production_detail; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_production_detail (id, header_id, roll_number, roll_weight, remarks, created_at) FROM stdin;
1194	167	1	24.600	\N	2026-08-15 06:12:14.852552
1195	167	2	27.550	\N	2026-08-15 06:12:14.852552
1196	167	3	36.050	\N	2026-08-15 06:12:14.852552
1197	167	4	25.250	\N	2026-08-15 06:12:14.852552
1198	167	5	33.950	\N	2026-08-15 06:12:14.852552
1199	167	6	34.450	\N	2026-08-15 06:12:14.852552
1200	167	7	32.700	\N	2026-08-15 06:12:14.852552
1201	167	8	28.900	\N	2026-08-15 06:12:14.852552
13	4	1	28.000	\N	2026-08-04 09:10:42.87511
14	4	2	29.450	\N	2026-08-04 09:10:42.87511
15	4	3	28.800	\N	2026-08-04 09:10:42.87511
16	4	4	23.300	\N	2026-08-04 09:10:42.87511
17	4	5	29.150	\N	2026-08-04 09:10:42.87511
18	4	6	23.600	\N	2026-08-04 09:10:42.87511
21	6	1	31.150	\N	2026-08-04 09:18:31.354253
22	6	2	29.900	\N	2026-08-04 09:18:31.354253
23	6	3	26.100	\N	2026-08-04 09:18:31.354253
24	6	4	30.350	\N	2026-08-04 09:18:31.354253
25	6	5	27.350	\N	2026-08-04 09:18:31.354253
26	6	6	11.300	\N	2026-08-04 09:18:31.354253
27	7	1	27.300	\N	2026-08-04 09:20:23.329666
28	7	2	17.100	\N	2026-08-04 09:20:23.329666
29	7	3	16.050	\N	2026-08-04 09:20:23.329666
30	7	4	20.550	\N	2026-08-04 09:20:23.329666
31	7	5	25.700	\N	2026-08-04 09:20:23.329666
32	7	6	21.300	\N	2026-08-04 09:20:23.329666
33	7	7	20.400	\N	2026-08-04 09:20:23.329666
36	5	1	29.250	\N	2026-08-04 09:23:18.321417
37	5	2	28.200	\N	2026-08-04 09:23:18.321417
38	5	3	30.850	\N	2026-08-04 09:23:18.321417
39	8	1	28.750	\N	2026-08-04 09:25:40.653893
40	8	2	35.100	\N	2026-08-04 09:25:40.653893
41	8	3	28.800	\N	2026-08-04 09:25:40.653893
42	8	4	28.300	\N	2026-08-04 09:25:40.653893
43	8	5	32.200	\N	2026-08-04 09:25:40.653893
44	8	6	21.750	\N	2026-08-04 09:25:40.653893
45	9	1	26.000	\N	2026-08-04 09:27:15.003235
46	9	2	27.700	\N	2026-08-04 09:27:15.003235
47	9	3	22.700	\N	2026-08-04 09:27:15.003235
48	9	4	29.400	\N	2026-08-04 09:27:15.003235
49	9	5	29.400	\N	2026-08-04 09:27:15.003235
50	9	6	25.850	\N	2026-08-04 09:27:15.003235
51	10	1	26.650	\N	2026-08-04 09:28:57.85111
52	10	2	28.300	\N	2026-08-04 09:28:57.85111
53	10	3	23.900	\N	2026-08-04 09:28:57.85111
54	10	4	19.900	\N	2026-08-04 09:28:57.85111
55	10	5	27.300	\N	2026-08-04 09:28:57.85111
56	10	6	19.200	\N	2026-08-04 09:28:57.85111
57	10	7	22.650	\N	2026-08-04 09:28:57.85111
58	11	1	19.150	\N	2026-08-04 09:30:40.700423
59	11	2	29.650	\N	2026-08-04 09:30:40.700423
60	11	3	29.450	\N	2026-08-04 09:30:40.700423
61	11	4	29.800	\N	2026-08-04 09:30:40.700423
62	11	5	15.300	\N	2026-08-04 09:30:40.700423
63	11	6	25.100	\N	2026-08-04 09:30:40.700423
64	12	1	30.700	\N	2026-08-04 09:34:40.40951
65	12	2	27.750	\N	2026-08-04 09:34:40.40951
66	12	3	36.850	\N	2026-08-04 09:34:40.40951
67	12	4	27.850	\N	2026-08-04 09:34:40.40951
68	12	5	27.800	\N	2026-08-04 09:34:40.40951
69	12	6	27.750	\N	2026-08-04 09:34:40.40951
70	12	7	27.700	\N	2026-08-04 09:34:40.40951
71	13	1	26.750	\N	2026-08-04 09:36:49.21394
72	13	2	26.150	\N	2026-08-04 09:36:49.21394
73	13	3	28.100	\N	2026-08-04 09:36:49.21394
74	13	4	28.100	\N	2026-08-04 09:36:49.21394
75	13	5	29.500	\N	2026-08-04 09:36:49.21394
76	13	6	26.900	\N	2026-08-04 09:36:49.21394
77	13	7	28.150	\N	2026-08-04 09:36:49.21394
78	13	8	29.350	\N	2026-08-04 09:36:49.21394
79	13	9	28.200	\N	2026-08-04 09:36:49.21394
80	14	1	28.900	\N	2026-08-04 09:37:42.188473
81	14	2	28.600	\N	2026-08-04 09:37:42.188473
82	14	3	28.750	\N	2026-08-04 09:37:42.188473
83	14	4	29.900	\N	2026-08-04 09:37:42.188473
84	15	1	26.400	\N	2026-08-04 09:40:48.902839
85	15	2	25.200	\N	2026-08-04 09:40:48.902839
86	15	3	25.700	\N	2026-08-04 09:40:48.902839
87	15	4	27.300	\N	2026-08-04 09:40:48.902839
90	17	1	29.550	\N	2026-08-04 09:45:30.288701
91	17	2	26.100	\N	2026-08-04 09:45:30.288701
92	17	3	24.700	\N	2026-08-04 09:45:30.288701
93	17	4	31.400	\N	2026-08-04 09:45:30.288701
94	17	5	27.550	\N	2026-08-04 09:45:30.288701
95	17	6	31.600	\N	2026-08-04 09:45:30.288701
96	17	7	29.550	\N	2026-08-04 09:45:30.288701
97	17	8	29.950	\N	2026-08-04 09:45:30.288701
98	18	1	33.750	\N	2026-08-04 09:46:52.771207
99	18	2	30.650	\N	2026-08-04 09:46:52.771207
100	18	3	25.900	\N	2026-08-04 09:46:52.771207
101	18	4	32.350	\N	2026-08-04 09:46:52.771207
102	18	5	30.600	\N	2026-08-04 09:46:52.771207
103	19	1	11.500	\N	2026-08-04 09:54:11.999346
104	19	2	24.800	\N	2026-08-04 09:54:11.999346
105	19	3	27.000	\N	2026-08-04 09:54:11.999346
106	19	4	27.050	\N	2026-08-04 09:54:11.999346
107	19	5	24.900	\N	2026-08-04 09:54:11.999346
108	19	6	27.900	\N	2026-08-04 09:54:11.999346
109	19	7	25.200	\N	2026-08-04 09:54:11.999346
110	19	8	25.850	\N	2026-08-04 09:54:11.999346
118	21	1	27.600	\N	2026-08-04 10:01:26.358251
119	21	2	28.750	\N	2026-08-04 10:01:26.358251
120	21	3	24.800	\N	2026-08-04 10:01:26.358251
121	21	4	30.950	\N	2026-08-04 10:01:26.358251
122	21	5	29.900	\N	2026-08-04 10:01:26.358251
123	21	6	29.400	\N	2026-08-04 10:01:26.358251
124	21	7	29.900	\N	2026-08-04 10:01:26.358251
125	22	1	29.500	\N	2026-08-04 10:02:51.515396
126	22	2	29.650	\N	2026-08-04 10:02:51.515396
127	22	3	29.500	\N	2026-08-04 10:02:51.515396
128	22	4	25.850	\N	2026-08-04 10:02:51.515396
129	22	5	34.700	\N	2026-08-04 10:02:51.515396
130	22	6	32.300	\N	2026-08-04 10:02:51.515396
131	22	7	29.500	\N	2026-08-04 10:02:51.515396
132	22	8	29.050	\N	2026-08-04 10:02:51.515396
133	22	9	26.750	\N	2026-08-04 10:02:51.515396
138	23	1	31.150	\N	2026-08-04 10:05:41.440994
139	23	2	28.400	\N	2026-08-04 10:05:41.440994
140	23	3	27.900	\N	2026-08-04 10:05:41.440994
141	23	4	28.850	\N	2026-08-04 10:05:41.440994
142	23	5	31.500	\N	2026-08-04 10:05:41.440994
143	23	6	26.850	\N	2026-08-04 10:05:41.440994
144	24	1	21.300	\N	2026-08-04 10:06:51.146146
145	24	2	25.050	\N	2026-08-04 10:06:51.146146
146	24	3	27.500	\N	2026-08-04 10:06:51.146146
147	24	4	28.850	\N	2026-08-04 10:06:51.146146
148	25	1	27.950	\N	2026-08-04 10:07:59.206754
149	25	2	28.100	\N	2026-08-04 10:07:59.206754
150	25	3	23.000	\N	2026-08-04 10:07:59.206754
151	25	4	23.450	\N	2026-08-04 10:07:59.206754
152	25	5	26.050	\N	2026-08-04 10:07:59.206754
153	25	6	20.000	\N	2026-08-04 10:07:59.206754
154	25	7	22.650	\N	2026-08-04 10:07:59.206754
155	25	8	28.150	\N	2026-08-04 10:07:59.206754
156	26	1	25.450	\N	2026-08-04 10:08:59.403701
157	26	2	29.000	\N	2026-08-04 10:08:59.403701
158	26	3	28.250	\N	2026-08-04 10:08:59.403701
159	26	4	20.850	\N	2026-08-04 10:08:59.403701
160	26	5	28.350	\N	2026-08-04 10:08:59.403701
161	26	6	18.850	\N	2026-08-04 10:08:59.403701
162	27	1	30.200	\N	2026-08-04 10:10:14.184358
163	27	2	30.000	\N	2026-08-04 10:10:14.184358
164	27	3	26.350	\N	2026-08-04 10:10:14.184358
165	27	4	25.850	\N	2026-08-04 10:10:14.184358
166	27	5	17.350	\N	2026-08-04 10:10:14.184358
167	27	6	28.350	\N	2026-08-04 10:10:14.184358
168	27	7	28.100	\N	2026-08-04 10:10:14.184358
169	28	1	30.200	\N	2026-08-04 10:11:18.644384
170	28	2	19.950	\N	2026-08-04 10:11:18.644384
171	28	3	29.500	\N	2026-08-04 10:11:18.644384
172	28	4	30.200	\N	2026-08-04 10:11:18.644384
173	28	5	28.950	\N	2026-08-04 10:11:18.644384
174	28	6	28.750	\N	2026-08-04 10:11:18.644384
175	29	1	31.500	\N	2026-08-04 10:44:10.948865
176	29	2	31.700	\N	2026-08-04 10:44:10.948865
177	29	3	35.950	\N	2026-08-04 10:44:10.948865
178	29	4	27.300	\N	2026-08-04 10:44:10.948865
179	29	5	28.950	\N	2026-08-04 10:44:10.948865
180	29	6	26.950	\N	2026-08-04 10:44:10.948865
181	29	7	29.000	\N	2026-08-04 10:44:10.948865
183	31	1	33.100	\N	2026-08-04 11:02:23.167923
184	31	2	29.550	\N	2026-08-04 11:02:23.167923
185	31	3	30.850	\N	2026-08-04 11:02:23.167923
186	31	4	29.150	\N	2026-08-04 11:02:23.167923
187	31	5	30.400	\N	2026-08-04 11:02:23.167923
188	31	6	32.450	\N	2026-08-04 11:02:23.167923
189	31	7	29.850	\N	2026-08-04 11:02:23.167923
190	31	8	28.100	\N	2026-08-04 11:02:23.167923
191	32	1	25.200	\N	2026-08-04 11:03:01.847261
192	32	2	31.050	\N	2026-08-04 11:03:01.847261
193	33	1	23.800	\N	2026-08-04 11:04:36.849782
194	34	1	30.850	\N	2026-08-04 11:05:46.793537
195	34	2	28.950	\N	2026-08-04 11:05:46.793537
196	34	3	29.400	\N	2026-08-04 11:05:46.793537
197	34	4	32.300	\N	2026-08-04 11:05:46.793537
198	34	5	25.700	\N	2026-08-04 11:05:46.793537
199	34	6	30.850	\N	2026-08-04 11:05:46.793537
200	34	7	31.650	\N	2026-08-04 11:05:46.793537
201	35	1	16.450	\N	2026-08-04 11:06:46.274667
202	35	2	26.550	\N	2026-08-04 11:06:46.274667
203	35	3	34.150	\N	2026-08-04 11:06:46.274667
204	35	4	31.000	\N	2026-08-04 11:06:46.274667
205	36	1	20.000	\N	2026-08-04 11:07:56.979945
206	36	2	25.200	\N	2026-08-04 11:07:56.979945
207	36	3	27.150	\N	2026-08-04 11:07:56.979945
208	36	4	25.500	\N	2026-08-04 11:07:56.979945
209	36	5	23.550	\N	2026-08-04 11:07:56.979945
210	36	6	27.400	\N	2026-08-04 11:07:56.979945
211	36	7	26.250	\N	2026-08-04 11:07:56.979945
212	36	8	9.900	\N	2026-08-04 11:07:56.979945
213	37	1	35.450	\N	2026-08-04 11:08:47.644403
214	37	2	28.250	\N	2026-08-04 11:08:47.644403
215	37	3	27.450	\N	2026-08-04 11:08:47.644403
216	38	1	29.300	\N	2026-08-04 11:10:01.18467
217	38	2	29.450	\N	2026-08-04 11:10:01.18467
218	38	3	29.600	\N	2026-08-04 11:10:01.18467
219	38	4	29.650	\N	2026-08-04 11:10:01.18467
220	38	5	21.300	\N	2026-08-04 11:10:01.18467
221	38	6	28.150	\N	2026-08-04 11:10:01.18467
222	39	1	29.650	\N	2026-08-04 11:14:57.548808
223	39	2	29.750	\N	2026-08-04 11:14:57.548808
224	39	3	29.550	\N	2026-08-04 11:14:57.548808
225	39	4	29.550	\N	2026-08-04 11:14:57.548808
226	39	5	29.750	\N	2026-08-04 11:14:57.548808
227	39	6	29.650	\N	2026-08-04 11:14:57.548808
228	39	7	24.200	\N	2026-08-04 11:14:57.548808
229	39	8	26.550	\N	2026-08-04 11:14:57.548808
230	39	9	28.050	\N	2026-08-04 11:14:57.548808
231	40	1	30.400	\N	2026-08-04 11:15:49.435534
232	40	2	32.000	\N	2026-08-04 11:15:49.435534
233	40	3	30.250	\N	2026-08-04 11:15:49.435534
234	40	4	31.000	\N	2026-08-04 11:15:49.435534
235	40	5	33.500	\N	2026-08-04 11:15:49.435534
236	41	1	21.750	\N	2026-08-04 11:16:54.358067
237	41	2	29.500	\N	2026-08-04 11:16:54.358067
238	41	3	21.850	\N	2026-08-04 11:16:54.358067
239	41	4	29.650	\N	2026-08-04 11:16:54.358067
240	41	5	16.400	\N	2026-08-04 11:16:54.358067
241	42	1	26.250	\N	2026-08-04 11:18:01.178238
242	42	2	26.000	\N	2026-08-04 11:18:01.178238
243	42	3	28.550	\N	2026-08-04 11:18:01.178238
244	42	4	29.850	\N	2026-08-04 11:18:01.178238
245	42	5	32.700	\N	2026-08-04 11:18:01.178238
246	42	6	32.100	\N	2026-08-04 11:18:01.178238
247	42	7	17.000	\N	2026-08-04 11:18:01.178238
248	43	1	26.500	\N	2026-08-04 11:18:37.003406
249	43	2	33.000	\N	2026-08-04 11:18:37.003406
250	43	3	30.350	\N	2026-08-04 11:18:37.003406
251	44	1	29.850	\N	2026-08-04 11:19:37.030411
252	44	2	28.400	\N	2026-08-04 11:19:37.030411
253	44	3	28.200	\N	2026-08-04 11:19:37.030411
254	44	4	27.000	\N	2026-08-04 11:19:37.030411
255	44	5	24.200	\N	2026-08-04 11:19:37.030411
256	44	6	24.700	\N	2026-08-04 11:19:37.030411
257	45	1	32.950	\N	2026-08-04 11:21:22.562363
258	45	2	33.400	\N	2026-08-04 11:21:22.562363
259	45	3	27.800	\N	2026-08-04 11:21:22.562363
260	45	4	25.900	\N	2026-08-04 11:21:22.562363
261	45	5	29.250	\N	2026-08-04 11:21:22.562363
262	45	6	27.250	\N	2026-08-04 11:21:22.562363
263	45	7	32.950	\N	2026-08-04 11:21:22.562363
264	46	1	32.750	\N	2026-08-04 11:22:21.680401
265	46	2	33.300	\N	2026-08-04 11:22:21.680401
266	46	3	34.250	\N	2026-08-04 11:22:21.680401
267	46	4	28.200	\N	2026-08-04 11:22:21.680401
268	46	5	28.050	\N	2026-08-04 11:22:21.680401
269	46	6	29.600	\N	2026-08-04 11:22:21.680401
270	46	7	30.450	\N	2026-08-04 11:22:21.680401
271	46	8	36.000	\N	2026-08-04 11:22:21.680401
272	47	1	22.800	\N	2026-08-04 11:23:27.891391
273	47	2	22.850	\N	2026-08-04 11:23:27.891391
274	47	3	28.750	\N	2026-08-04 11:23:27.891391
275	47	4	30.550	\N	2026-08-04 11:23:27.891391
276	47	5	31.000	\N	2026-08-04 11:23:27.891391
277	47	6	29.750	\N	2026-08-04 11:23:27.891391
278	47	7	29.300	\N	2026-08-04 11:23:27.891391
279	47	8	28.800	\N	2026-08-04 11:23:27.891391
280	48	1	21.800	\N	2026-08-04 11:24:21.364634
281	48	2	24.000	\N	2026-08-04 11:24:21.364634
282	48	3	27.200	\N	2026-08-04 11:24:21.364634
283	48	4	27.700	\N	2026-08-04 11:24:21.364634
284	48	5	26.300	\N	2026-08-04 11:24:21.364634
285	49	1	19.000	\N	2026-08-04 11:25:27.95248
286	49	2	32.450	\N	2026-08-04 11:25:27.95248
287	49	3	25.900	\N	2026-08-04 11:25:27.95248
288	49	4	32.000	\N	2026-08-04 11:25:27.95248
289	49	5	22.800	\N	2026-08-04 11:25:27.95248
290	49	6	25.800	\N	2026-08-04 11:25:27.95248
291	49	7	31.150	\N	2026-08-04 11:25:27.95248
292	49	8	29.250	\N	2026-08-04 11:25:27.95248
293	50	1	19.600	\N	2026-08-04 11:26:53.291837
294	50	2	19.650	\N	2026-08-04 11:26:53.291837
295	50	3	26.300	\N	2026-08-04 11:26:53.291837
296	50	4	25.850	\N	2026-08-04 11:26:53.291837
297	50	5	28.200	\N	2026-08-04 11:26:53.291837
298	50	6	27.450	\N	2026-08-04 11:26:53.291837
299	50	7	25.550	\N	2026-08-04 11:26:53.291837
300	50	8	27.000	\N	2026-08-04 11:26:53.291837
301	16	1	25.600	\N	2026-08-04 13:45:14.162052
302	16	2	14.100	\N	2026-08-04 13:45:14.162052
1202	168	1	28.150	\N	2026-08-16 07:15:31.554374
1203	168	2	29.000	\N	2026-08-16 07:15:31.554374
1204	168	3	28.700	\N	2026-08-16 07:15:31.554374
1205	168	4	24.950	\N	2026-08-16 07:15:31.554374
1206	168	5	27.750	\N	2026-08-16 07:15:31.554374
1207	168	6	27.400	\N	2026-08-16 07:15:31.554374
1208	168	7	29.350	\N	2026-08-16 07:15:31.554374
318	53	1	28.500	\N	2026-08-05 05:19:28.381793
319	53	2	28.750	\N	2026-08-05 05:19:28.381793
320	53	3	20.050	\N	2026-08-05 05:19:28.381793
321	53	4	30.050	\N	2026-08-05 05:19:28.381793
322	53	5	34.200	\N	2026-08-05 05:19:28.381793
323	53	6	32.950	\N	2026-08-05 05:19:28.381793
324	53	7	35.650	\N	2026-08-05 05:19:28.381793
325	54	1	15.100	\N	2026-08-05 05:20:10.782671
1254	176	1	30.200	\N	2026-08-16 07:25:54.684036
1255	176	2	30.600	\N	2026-08-16 07:25:54.684036
1256	176	3	30.250	\N	2026-08-16 07:25:54.684036
1257	176	4	31.600	\N	2026-08-16 07:25:54.684036
332	56	1	28.800	\N	2026-08-05 05:22:54.381768
333	56	2	27.600	\N	2026-08-05 05:22:54.381768
334	56	3	29.450	\N	2026-08-05 05:22:54.381768
335	56	4	28.900	\N	2026-08-05 05:22:54.381768
336	56	5	27.750	\N	2026-08-05 05:22:54.381768
337	56	6	26.050	\N	2026-08-05 05:22:54.381768
338	56	7	25.650	\N	2026-08-05 05:22:54.381768
339	57	1	32.050	\N	2026-08-05 05:23:56.914664
340	57	2	32.050	\N	2026-08-05 05:23:56.914664
341	57	3	35.600	\N	2026-08-05 05:23:56.914664
342	57	4	32.100	\N	2026-08-05 05:23:56.914664
343	57	5	34.250	\N	2026-08-05 05:23:56.914664
344	57	6	33.500	\N	2026-08-05 05:23:56.914664
345	57	7	31.300	\N	2026-08-05 05:23:56.914664
346	57	8	35.200	\N	2026-08-05 05:23:56.914664
347	58	1	20.000	\N	2026-08-05 05:25:07.609832
348	58	2	23.100	\N	2026-08-05 05:25:07.609832
349	58	3	31.450	\N	2026-08-05 05:25:07.609832
350	58	4	33.950	\N	2026-08-05 05:25:07.609832
351	58	5	31.350	\N	2026-08-05 05:25:07.609832
352	58	6	34.300	\N	2026-08-05 05:25:07.609832
353	58	7	33.650	\N	2026-08-05 05:25:07.609832
354	58	8	32.800	\N	2026-08-05 05:25:07.609832
355	58	9	35.050	\N	2026-08-05 05:25:07.609832
356	59	1	26.550	\N	2026-08-05 05:26:18.500287
357	59	2	26.400	\N	2026-08-05 05:26:18.500287
358	59	3	26.800	\N	2026-08-05 05:26:18.500287
359	59	4	26.200	\N	2026-08-05 05:26:18.500287
360	59	5	26.850	\N	2026-08-05 05:26:18.500287
361	59	6	27.250	\N	2026-08-05 05:26:18.500287
362	59	7	26.150	\N	2026-08-05 05:26:18.500287
363	59	8	26.550	\N	2026-08-05 05:26:18.500287
370	52	1	29.650	\N	2026-08-05 14:53:59.237638
371	52	2	27.800	\N	2026-08-05 14:53:59.237638
372	52	3	29.600	\N	2026-08-05 14:53:59.237638
373	52	4	29.150	\N	2026-08-05 14:53:59.237638
374	52	5	29.750	\N	2026-08-05 14:53:59.237638
375	52	6	28.800	\N	2026-08-05 14:53:59.237638
376	52	7	29.650	\N	2026-08-05 14:53:59.237638
377	52	8	19.850	\N	2026-08-05 14:53:59.237638
378	52	9	28.550	\N	2026-08-05 14:53:59.237638
385	51	1	28.100	\N	2026-08-05 23:02:26.289543
386	51	2	29.050	\N	2026-08-05 23:02:26.289543
387	51	3	28.250	\N	2026-08-05 23:02:26.289543
388	51	4	29.800	\N	2026-08-05 23:02:26.289543
389	51	5	28.000	\N	2026-08-05 23:02:26.289543
390	51	6	27.850	\N	2026-08-05 23:02:26.289543
391	60	1	28.400	\N	2026-08-06 05:12:09.379561
392	60	2	29.650	\N	2026-08-06 05:12:09.379561
393	60	3	29.700	\N	2026-08-06 05:12:09.379561
394	60	4	27.750	\N	2026-08-06 05:12:09.379561
395	60	5	17.350	\N	2026-08-06 05:12:09.379561
396	60	6	27.850	\N	2026-08-06 05:12:09.379561
397	60	7	14.300	\N	2026-08-06 05:12:09.379561
398	61	1	31.350	\N	2026-08-06 05:13:41.179759
399	61	2	31.450	\N	2026-08-06 05:13:41.179759
400	61	3	29.650	\N	2026-08-06 05:13:41.179759
401	61	4	29.800	\N	2026-08-06 05:13:41.179759
402	61	5	32.100	\N	2026-08-06 05:13:41.179759
403	61	6	32.100	\N	2026-08-06 05:13:41.179759
404	61	7	30.900	\N	2026-08-06 05:13:41.179759
405	61	8	32.650	\N	2026-08-06 05:13:41.179759
406	61	9	31.750	\N	2026-08-06 05:13:41.179759
407	62	1	30.800	\N	2026-08-06 05:14:54.170255
408	62	2	31.700	\N	2026-08-06 05:14:54.170255
409	62	3	31.100	\N	2026-08-06 05:14:54.170255
410	62	4	30.550	\N	2026-08-06 05:14:54.170255
411	62	5	34.150	\N	2026-08-06 05:14:54.170255
412	62	6	30.600	\N	2026-08-06 05:14:54.170255
413	62	7	29.650	\N	2026-08-06 05:14:54.170255
414	62	8	21.000	\N	2026-08-06 05:14:54.170255
415	62	9	26.600	\N	2026-08-06 05:14:54.170255
423	64	1	24.850	\N	2026-08-06 05:18:20.391739
424	64	2	28.250	\N	2026-08-06 05:18:20.391739
431	66	1	27.350	\N	2026-08-06 05:21:03.119254
432	66	2	28.900	\N	2026-08-06 05:21:03.119254
433	66	3	31.300	\N	2026-08-06 05:21:03.119254
434	66	4	27.400	\N	2026-08-06 05:21:03.119254
435	66	5	34.150	\N	2026-08-06 05:21:03.119254
436	66	6	27.250	\N	2026-08-06 05:21:03.119254
437	66	7	25.650	\N	2026-08-06 05:21:03.119254
438	66	8	29.150	\N	2026-08-06 05:21:03.119254
439	66	9	37.900	\N	2026-08-06 05:21:03.119254
440	67	1	29.050	\N	2026-08-06 05:23:48.398276
441	67	2	26.500	\N	2026-08-06 05:23:48.398276
442	67	3	28.100	\N	2026-08-06 05:23:48.398276
443	67	4	26.050	\N	2026-08-06 05:23:48.398276
444	67	5	27.400	\N	2026-08-06 05:23:48.398276
445	67	6	28.550	\N	2026-08-06 05:23:48.398276
446	67	7	28.850	\N	2026-08-06 05:23:48.398276
447	67	8	26.000	\N	2026-08-06 05:23:48.398276
448	67	9	26.700	\N	2026-08-06 05:23:48.398276
449	67	10	29.150	\N	2026-08-06 05:23:48.398276
450	68	1	23.600	\N	2026-08-06 05:24:47.564861
451	68	2	27.250	\N	2026-08-06 05:24:47.564861
452	68	3	26.450	\N	2026-08-06 05:24:47.564861
453	68	4	26.650	\N	2026-08-06 05:24:47.564861
454	68	5	30.650	\N	2026-08-06 05:24:47.564861
455	68	6	26.600	\N	2026-08-06 05:24:47.564861
456	68	7	28.800	\N	2026-08-06 05:24:47.564861
457	69	1	33.300	\N	2026-08-06 05:25:38.115455
458	69	2	28.150	\N	2026-08-06 05:25:38.115455
459	69	3	25.000	\N	2026-08-06 05:25:38.115455
460	69	4	27.050	\N	2026-08-06 05:25:38.115455
461	69	5	27.150	\N	2026-08-06 05:25:38.115455
462	69	6	30.850	\N	2026-08-06 05:25:38.115455
463	65	1	22.850	\N	2026-08-06 05:26:52.715078
464	65	2	26.450	\N	2026-08-06 05:26:52.715078
465	65	3	26.750	\N	2026-08-06 05:26:52.715078
466	65	4	26.150	\N	2026-08-06 05:26:52.715078
467	65	5	27.800	\N	2026-08-06 05:26:52.715078
468	65	6	28.600	\N	2026-08-06 05:26:52.715078
469	63	1	27.650	\N	2026-08-06 09:50:06.52753
470	63	2	26.650	\N	2026-08-06 09:50:06.52753
471	63	3	34.250	\N	2026-08-06 09:50:06.52753
472	63	4	18.350	\N	2026-08-06 09:50:06.52753
473	63	5	26.350	\N	2026-08-06 09:50:06.52753
474	63	6	30.450	\N	2026-08-06 09:50:06.52753
475	63	7	20.650	\N	2026-08-06 09:50:06.52753
476	55	1	25.000	\N	2026-08-06 10:19:47.339954
477	55	2	22.600	\N	2026-08-06 10:19:47.339954
478	55	3	26.650	\N	2026-08-06 10:19:47.339954
479	55	4	26.650	\N	2026-08-06 10:19:47.339954
480	55	5	22.500	\N	2026-08-06 10:19:47.339954
481	55	6	21.650	\N	2026-08-06 10:19:47.339954
482	70	1	29.050	\N	2026-08-07 05:23:01.634685
483	70	2	29.200	\N	2026-08-07 05:23:01.634685
484	70	3	30.250	\N	2026-08-07 05:23:01.634685
485	70	4	33.650	\N	2026-08-07 05:23:01.634685
486	70	5	27.650	\N	2026-08-07 05:23:01.634685
487	70	6	29.950	\N	2026-08-07 05:23:01.634685
488	71	1	30.950	\N	2026-08-07 05:25:39.804931
489	71	2	29.550	\N	2026-08-07 05:25:39.804931
490	71	3	27.800	\N	2026-08-07 05:25:39.804931
491	71	4	28.500	\N	2026-08-07 05:25:39.804931
492	71	5	28.700	\N	2026-08-07 05:25:39.804931
493	71	6	23.000	\N	2026-08-07 05:25:39.804931
494	71	7	29.750	\N	2026-08-07 05:25:39.804931
495	71	8	28.050	\N	2026-08-07 05:25:39.804931
496	71	9	33.100	\N	2026-08-07 05:25:39.804931
497	72	1	21.750	\N	2026-08-07 05:26:45.829478
498	72	2	28.300	\N	2026-08-07 05:26:45.829478
499	72	3	30.550	\N	2026-08-07 05:26:45.829478
500	72	4	29.300	\N	2026-08-07 05:26:45.829478
501	72	5	29.950	\N	2026-08-07 05:26:45.829478
502	72	6	27.950	\N	2026-08-07 05:26:45.829478
503	72	7	28.400	\N	2026-08-07 05:26:45.829478
504	72	8	29.850	\N	2026-08-07 05:26:45.829478
505	72	9	30.350	\N	2026-08-07 05:26:45.829478
506	73	1	28.200	\N	2026-08-07 05:27:39.547294
507	73	2	31.700	\N	2026-08-07 05:27:39.547294
508	73	3	32.700	\N	2026-08-07 05:27:39.547294
509	73	4	31.650	\N	2026-08-07 05:27:39.547294
510	73	5	25.000	\N	2026-08-07 05:27:39.547294
511	74	1	28.550	\N	2026-08-07 05:28:49.295736
512	74	2	27.400	\N	2026-08-07 05:28:49.295736
513	74	3	27.400	\N	2026-08-07 05:28:49.295736
514	74	4	28.250	\N	2026-08-07 05:28:49.295736
515	74	5	18.450	\N	2026-08-07 05:28:49.295736
516	75	1	37.050	\N	2026-08-07 05:29:56.839702
517	75	2	34.600	\N	2026-08-07 05:29:56.839702
518	75	3	28.800	\N	2026-08-07 05:29:56.839702
519	75	4	24.750	\N	2026-08-07 05:29:56.839702
520	75	5	27.250	\N	2026-08-07 05:29:56.839702
521	75	6	27.600	\N	2026-08-07 05:29:56.839702
522	75	7	28.800	\N	2026-08-07 05:29:56.839702
523	75	8	27.500	\N	2026-08-07 05:29:56.839702
524	76	1	20.050	\N	2026-08-07 05:31:51.762381
525	76	2	28.200	\N	2026-08-07 05:31:51.762381
526	76	3	20.450	\N	2026-08-07 05:31:51.762381
527	76	4	27.400	\N	2026-08-07 05:31:51.762381
528	76	5	25.400	\N	2026-08-07 05:31:51.762381
529	76	6	29.100	\N	2026-08-07 05:31:51.762381
530	76	7	25.750	\N	2026-08-07 05:31:51.762381
531	76	8	28.400	\N	2026-08-07 05:31:51.762381
532	76	9	26.250	\N	2026-08-07 05:31:51.762381
533	76	10	28.750	\N	2026-08-07 05:31:51.762381
534	77	1	21.150	\N	2026-08-07 05:33:08.312801
535	77	2	20.600	\N	2026-08-07 05:33:08.312801
536	77	3	27.300	\N	2026-08-07 05:33:08.312801
537	77	4	26.900	\N	2026-08-07 05:33:08.312801
538	77	5	27.650	\N	2026-08-07 05:33:08.312801
539	77	6	30.100	\N	2026-08-07 05:33:08.312801
540	77	7	27.200	\N	2026-08-07 05:33:08.312801
541	77	8	28.800	\N	2026-08-07 05:33:08.312801
542	77	9	27.400	\N	2026-08-07 05:33:08.312801
543	77	10	28.650	\N	2026-08-07 05:33:08.312801
544	78	1	16.650	\N	2026-08-07 05:34:13.840169
545	78	2	27.000	\N	2026-08-07 05:34:13.840169
546	78	3	17.200	\N	2026-08-07 05:34:13.840169
547	78	4	27.550	\N	2026-08-07 05:34:13.840169
548	78	5	28.200	\N	2026-08-07 05:34:13.840169
549	78	6	26.500	\N	2026-08-07 05:34:13.840169
550	78	7	27.150	\N	2026-08-07 05:34:13.840169
551	78	8	28.350	\N	2026-08-07 05:34:13.840169
552	79	1	30.750	\N	2026-08-07 05:35:10.784899
553	79	2	26.450	\N	2026-08-07 05:35:10.784899
554	79	3	28.050	\N	2026-08-07 05:35:10.784899
555	79	4	27.100	\N	2026-08-07 05:35:10.784899
556	79	5	26.300	\N	2026-08-07 05:35:10.784899
557	79	6	28.650	\N	2026-08-07 05:35:10.784899
558	79	7	27.400	\N	2026-08-07 05:35:10.784899
1209	169	1	26.100	\N	2026-08-16 07:16:46.800647
1210	169	2	25.550	\N	2026-08-16 07:16:46.800647
1211	169	3	25.700	\N	2026-08-16 07:16:46.800647
1212	169	4	28.100	\N	2026-08-16 07:16:46.800647
1213	169	5	27.450	\N	2026-08-16 07:16:46.800647
1214	169	6	28.200	\N	2026-08-16 07:16:46.800647
1215	169	7	29.850	\N	2026-08-16 07:16:46.800647
1237	174	1	29.100	\N	2026-08-16 07:23:35.942302
1238	174	2	29.950	\N	2026-08-16 07:23:35.942302
1239	174	3	25.700	\N	2026-08-16 07:23:35.942302
1240	174	4	25.500	\N	2026-08-16 07:23:35.942302
1241	174	5	24.750	\N	2026-08-16 07:23:35.942302
1242	174	6	28.050	\N	2026-08-16 07:23:35.942302
1243	174	7	26.700	\N	2026-08-16 07:23:35.942302
1244	174	8	27.900	\N	2026-08-16 07:23:35.942302
1245	174	9	26.900	\N	2026-08-16 07:23:35.942302
1258	176	5	30.150	\N	2026-08-16 07:25:54.684036
1259	176	6	29.850	\N	2026-08-16 07:25:54.684036
1260	176	7	20.150	\N	2026-08-16 07:25:54.684036
1261	177	1	23.300	\N	2026-08-16 07:27:02.334141
1262	177	2	24.850	\N	2026-08-16 07:27:02.334141
1263	177	3	24.250	\N	2026-08-16 07:27:02.334141
1264	177	4	24.350	\N	2026-08-16 07:27:02.334141
1265	177	5	27.900	\N	2026-08-16 07:27:02.334141
1266	177	6	26.000	\N	2026-08-16 07:27:02.334141
1267	178	1	26.150	\N	2026-08-17 05:21:35.499855
1268	178	2	28.650	\N	2026-08-17 05:21:35.499855
1269	178	3	27.900	\N	2026-08-17 05:21:35.499855
1270	178	4	29.200	\N	2026-08-17 05:21:35.499855
1271	178	5	31.000	\N	2026-08-17 05:21:35.499855
1216	170	1	27.700	\N	2026-08-16 07:17:47.960176
1217	170	2	26.900	\N	2026-08-16 07:17:47.960176
1246	175	1	23.800	\N	2026-08-16 07:24:50.375929
1247	175	2	23.150	\N	2026-08-16 07:24:50.375929
1248	175	3	24.600	\N	2026-08-16 07:24:50.375929
1249	175	4	24.250	\N	2026-08-16 07:24:50.375929
1250	175	5	22.500	\N	2026-08-16 07:24:50.375929
619	20	1	28.000	\N	2026-08-07 12:32:39.042585
620	20	2	32.950	\N	2026-08-07 12:32:39.042585
621	20	3	27.950	\N	2026-08-07 12:32:39.042585
622	20	4	27.850	\N	2026-08-07 12:32:39.042585
623	20	5	27.900	\N	2026-08-07 12:32:39.042585
624	20	6	28.450	\N	2026-08-07 12:32:39.042585
625	20	7	29.300	\N	2026-08-07 12:32:39.042585
627	88	1	28.600	\N	2026-08-08 05:33:43.300283
628	88	2	29.750	\N	2026-08-08 05:33:43.300283
629	88	3	29.400	\N	2026-08-08 05:33:43.300283
630	88	4	29.350	\N	2026-08-08 05:33:43.300283
631	88	5	29.850	\N	2026-08-08 05:33:43.300283
632	88	6	30.650	\N	2026-08-08 05:33:43.300283
633	89	1	27.350	\N	2026-08-08 05:34:49.051626
634	89	2	27.450	\N	2026-08-08 05:34:49.051626
635	89	3	27.550	\N	2026-08-08 05:34:49.051626
636	89	4	29.100	\N	2026-08-08 05:34:49.051626
637	89	5	27.500	\N	2026-08-08 05:34:49.051626
638	89	6	27.550	\N	2026-08-08 05:34:49.051626
639	89	7	27.450	\N	2026-08-08 05:34:49.051626
640	89	8	23.300	\N	2026-08-08 05:34:49.051626
641	90	1	30.500	\N	2026-08-08 05:35:45.485175
642	90	2	27.550	\N	2026-08-08 05:35:45.485175
643	90	3	28.100	\N	2026-08-08 05:35:45.485175
644	90	4	27.700	\N	2026-08-08 05:35:45.485175
645	90	5	28.550	\N	2026-08-08 05:35:45.485175
646	90	6	21.500	\N	2026-08-08 05:35:45.485175
647	90	7	30.050	\N	2026-08-08 05:35:45.485175
648	91	1	26.050	\N	2026-08-08 05:37:33.883171
649	91	2	26.900	\N	2026-08-08 05:37:33.883171
650	91	3	29.850	\N	2026-08-08 05:37:33.883171
651	91	4	27.650	\N	2026-08-08 05:37:33.883171
652	91	5	20.000	\N	2026-08-08 05:37:33.883171
653	91	6	23.450	\N	2026-08-08 05:37:33.883171
654	92	1	21.600	\N	2026-08-08 05:39:02.666522
655	92	2	28.700	\N	2026-08-08 05:39:02.666522
656	92	3	30.000	\N	2026-08-08 05:39:02.666522
657	92	4	28.450	\N	2026-08-08 05:39:02.666522
658	92	5	26.800	\N	2026-08-08 05:39:02.666522
659	93	1	27.300	\N	2026-08-08 05:41:02.110074
660	93	2	27.300	\N	2026-08-08 05:41:02.110074
661	93	3	25.400	\N	2026-08-08 05:41:02.110074
662	93	4	27.250	\N	2026-08-08 05:41:02.110074
663	93	5	28.050	\N	2026-08-08 05:41:02.110074
664	93	6	27.350	\N	2026-08-08 05:41:02.110074
665	93	7	27.250	\N	2026-08-08 05:41:02.110074
666	93	8	25.000	\N	2026-08-08 05:41:02.110074
667	93	9	29.600	\N	2026-08-08 05:41:02.110074
668	94	1	32.400	\N	2026-08-08 05:42:10.302604
669	94	2	27.450	\N	2026-08-08 05:42:10.302604
670	94	3	27.250	\N	2026-08-08 05:42:10.302604
671	94	4	29.000	\N	2026-08-08 05:42:10.302604
672	94	5	27.250	\N	2026-08-08 05:42:10.302604
673	94	6	27.200	\N	2026-08-08 05:42:10.302604
674	94	7	29.000	\N	2026-08-08 05:42:10.302604
675	94	8	27.250	\N	2026-08-08 05:42:10.302604
676	94	9	25.650	\N	2026-08-08 05:42:10.302604
677	94	10	28.950	\N	2026-08-08 05:42:10.302604
678	95	1	26.000	\N	2026-08-08 05:43:24.316785
679	95	2	29.750	\N	2026-08-08 05:43:24.316785
680	95	3	27.300	\N	2026-08-08 05:43:24.316785
681	95	4	24.900	\N	2026-08-08 05:43:24.316785
682	95	5	28.950	\N	2026-08-08 05:43:24.316785
683	95	6	30.300	\N	2026-08-08 05:43:24.316785
684	95	7	27.650	\N	2026-08-08 05:43:24.316785
685	95	8	25.600	\N	2026-08-08 05:43:24.316785
686	95	9	29.100	\N	2026-08-08 05:43:24.316785
687	95	10	30.650	\N	2026-08-08 05:43:24.316785
688	96	1	20.300	\N	2026-08-08 05:44:27.618161
689	96	2	26.250	\N	2026-08-08 05:44:27.618161
690	96	3	26.400	\N	2026-08-08 05:44:27.618161
691	96	4	26.350	\N	2026-08-08 05:44:27.618161
692	96	5	26.250	\N	2026-08-08 05:44:27.618161
693	96	6	26.700	\N	2026-08-08 05:44:27.618161
694	96	7	26.500	\N	2026-08-08 05:44:27.618161
695	96	8	28.150	\N	2026-08-08 05:44:27.618161
696	97	1	27.500	\N	2026-08-08 05:45:15.246474
697	97	2	27.400	\N	2026-08-08 05:45:15.246474
698	97	3	26.200	\N	2026-08-08 05:45:15.246474
699	97	4	29.000	\N	2026-08-08 05:45:15.246474
700	97	5	34.850	\N	2026-08-08 05:45:15.246474
701	97	6	30.500	\N	2026-08-08 05:45:15.246474
702	98	1	694.750	\N	2026-08-08 06:51:30.145466
703	99	1	1534.500	\N	2026-08-08 06:58:00.950157
704	100	1	2181.850	\N	2026-08-08 07:01:29.883679
705	101	1	17.900	\N	2026-08-08 07:05:24.210104
706	102	1	520.900	\N	2026-08-08 07:07:33.221562
707	103	1	439.600	\N	2026-08-08 07:12:47.109305
708	104	1	2100.900	\N	2026-08-08 07:31:28.848027
709	105	1	29.250	\N	2026-08-09 07:48:31.9882
710	105	2	28.750	\N	2026-08-09 07:48:31.9882
711	105	3	29.450	\N	2026-08-09 07:48:31.9882
712	105	4	28.050	\N	2026-08-09 07:48:31.9882
713	105	5	30.000	\N	2026-08-09 07:48:31.9882
714	105	6	29.500	\N	2026-08-09 07:48:31.9882
715	105	7	29.400	\N	2026-08-09 07:48:31.9882
716	105	8	30.500	\N	2026-08-09 07:48:31.9882
717	106	1	27.450	\N	2026-08-09 07:50:05.863588
718	106	2	27.450	\N	2026-08-09 07:50:05.863588
719	106	3	29.350	\N	2026-08-09 07:50:05.863588
720	106	4	27.850	\N	2026-08-09 07:50:05.863588
721	106	5	27.550	\N	2026-08-09 07:50:05.863588
722	106	6	27.500	\N	2026-08-09 07:50:05.863588
723	106	7	27.450	\N	2026-08-09 07:50:05.863588
724	106	8	24.600	\N	2026-08-09 07:50:05.863588
725	106	9	27.400	\N	2026-08-09 07:50:05.863588
726	106	10	31.700	\N	2026-08-09 07:50:05.863588
727	107	1	32.850	\N	2026-08-09 07:51:04.678261
728	107	2	27.050	\N	2026-08-09 07:51:04.678261
729	107	3	27.750	\N	2026-08-09 07:51:04.678261
730	107	4	29.150	\N	2026-08-09 07:51:04.678261
731	107	5	27.300	\N	2026-08-09 07:51:04.678261
732	107	6	27.500	\N	2026-08-09 07:51:04.678261
733	107	7	27.550	\N	2026-08-09 07:51:04.678261
734	107	8	30.550	\N	2026-08-09 07:51:04.678261
735	107	9	32.150	\N	2026-08-09 07:51:04.678261
736	108	1	28.400	\N	2026-08-09 07:52:30.892115
737	108	2	28.650	\N	2026-08-09 07:52:30.892115
738	108	3	23.900	\N	2026-08-09 07:52:30.892115
739	108	4	25.900	\N	2026-08-09 07:52:30.892115
740	108	5	21.450	\N	2026-08-09 07:52:30.892115
741	108	6	27.000	\N	2026-08-09 07:52:30.892115
742	109	1	28.650	\N	2026-08-09 07:53:28.839697
743	109	2	29.100	\N	2026-08-09 07:53:28.839697
744	109	3	28.650	\N	2026-08-09 07:53:28.839697
745	109	4	28.100	\N	2026-08-09 07:53:28.839697
746	109	5	10.600	\N	2026-08-09 07:53:28.839697
756	111	1	28.800	\N	2026-08-09 07:56:12.533537
757	111	2	29.550	\N	2026-08-09 07:56:12.533537
758	111	3	28.100	\N	2026-08-09 07:56:12.533537
759	111	4	23.700	\N	2026-08-09 07:56:12.533537
760	111	5	28.750	\N	2026-08-09 07:56:12.533537
761	111	6	27.200	\N	2026-08-09 07:56:12.533537
762	111	7	27.300	\N	2026-08-09 07:56:12.533537
763	111	8	28.900	\N	2026-08-09 07:56:12.533537
764	111	9	26.500	\N	2026-08-09 07:56:12.533537
765	111	10	27.300	\N	2026-08-09 07:56:12.533537
766	112	1	24.800	\N	2026-08-09 07:58:42.067577
767	112	2	28.050	\N	2026-08-09 07:58:42.067577
768	112	3	28.000	\N	2026-08-09 07:58:42.067577
769	112	4	28.850	\N	2026-08-09 07:58:42.067577
770	112	5	27.100	\N	2026-08-09 07:58:42.067577
771	112	6	27.550	\N	2026-08-09 07:58:42.067577
772	112	7	27.000	\N	2026-08-09 07:58:42.067577
773	112	8	29.050	\N	2026-08-09 07:58:42.067577
774	112	9	27.150	\N	2026-08-09 07:58:42.067577
775	112	10	29.450	\N	2026-08-09 07:58:42.067577
776	113	1	18.300	\N	2026-08-09 07:59:33.485241
777	113	2	27.000	\N	2026-08-09 07:59:33.485241
778	113	3	32.900	\N	2026-08-09 07:59:33.485241
779	113	4	28.050	\N	2026-08-09 07:59:33.485241
780	113	5	26.200	\N	2026-08-09 07:59:33.485241
781	113	6	34.600	\N	2026-08-09 07:59:33.485241
790	115	1	22.250	\N	2026-08-09 08:03:42.711767
791	115	2	26.150	\N	2026-08-09 08:03:42.711767
792	115	3	26.350	\N	2026-08-09 08:03:42.711767
793	115	4	23.200	\N	2026-08-09 08:03:42.711767
794	115	5	28.400	\N	2026-08-09 08:03:42.711767
795	115	6	27.700	\N	2026-08-09 08:03:42.711767
796	115	7	26.800	\N	2026-08-09 08:03:42.711767
797	115	8	27.500	\N	2026-08-09 08:03:42.711767
798	114	1	28.250	\N	2026-08-09 08:05:59.593048
799	114	2	26.100	\N	2026-08-09 08:05:59.593048
800	114	3	26.350	\N	2026-08-09 08:05:59.593048
801	114	4	26.350	\N	2026-08-09 08:05:59.593048
802	114	5	27.000	\N	2026-08-09 08:05:59.593048
803	114	6	26.550	\N	2026-08-09 08:05:59.593048
804	114	7	26.300	\N	2026-08-09 08:05:59.593048
805	114	8	26.450	\N	2026-08-09 08:05:59.593048
806	110	1	28.950	\N	2026-08-09 08:41:15.456616
807	110	2	20.450	\N	2026-08-09 08:41:15.456616
808	110	3	27.400	\N	2026-08-09 08:41:15.456616
809	110	4	27.250	\N	2026-08-09 08:41:15.456616
810	110	5	26.700	\N	2026-08-09 08:41:15.456616
811	110	6	27.250	\N	2026-08-09 08:41:15.456616
812	110	7	29.250	\N	2026-08-09 08:41:15.456616
813	110	8	27.350	\N	2026-08-09 08:41:15.456616
814	110	9	26.850	\N	2026-08-09 08:41:15.456616
815	116	1	27.900	\N	2026-08-10 05:23:01.976288
816	116	2	29.800	\N	2026-08-10 05:23:01.976288
817	116	3	27.250	\N	2026-08-10 05:23:01.976288
818	116	4	28.650	\N	2026-08-10 05:23:01.976288
819	116	5	30.800	\N	2026-08-10 05:23:01.976288
820	116	6	28.950	\N	2026-08-10 05:23:01.976288
821	117	1	29.550	\N	2026-08-10 05:24:06.205199
822	117	2	29.250	\N	2026-08-10 05:24:06.205199
823	117	3	28.950	\N	2026-08-10 05:24:06.205199
824	117	4	30.150	\N	2026-08-10 05:24:06.205199
825	117	5	29.150	\N	2026-08-10 05:24:06.205199
826	117	6	29.250	\N	2026-08-10 05:24:06.205199
827	117	7	28.350	\N	2026-08-10 05:24:06.205199
828	117	8	26.300	\N	2026-08-10 05:24:06.205199
829	117	9	26.500	\N	2026-08-10 05:24:06.205199
830	117	10	28.500	\N	2026-08-10 05:24:06.205199
831	118	1	29.350	\N	2026-08-10 05:25:09.40753
832	118	2	30.350	\N	2026-08-10 05:25:09.40753
833	118	3	28.150	\N	2026-08-10 05:25:09.40753
834	118	4	29.200	\N	2026-08-10 05:25:09.40753
835	118	5	27.700	\N	2026-08-10 05:25:09.40753
836	118	6	31.550	\N	2026-08-10 05:25:09.40753
837	118	7	27.600	\N	2026-08-10 05:25:09.40753
838	118	8	28.050	\N	2026-08-10 05:25:09.40753
839	118	9	30.600	\N	2026-08-10 05:25:09.40753
840	119	1	26.800	\N	2026-08-10 05:26:09.923348
841	119	2	25.150	\N	2026-08-10 05:26:09.923348
842	119	3	15.950	\N	2026-08-10 05:26:09.923348
843	119	4	16.450	\N	2026-08-10 05:26:09.923348
844	119	5	20.350	\N	2026-08-10 05:26:09.923348
845	119	6	20.350	\N	2026-08-10 05:26:09.923348
846	119	7	17.350	\N	2026-08-10 05:26:09.923348
847	119	8	24.000	\N	2026-08-10 05:26:09.923348
848	119	9	22.900	\N	2026-08-10 05:26:09.923348
849	120	1	20.250	\N	2026-08-10 05:27:03.589931
850	120	2	24.450	\N	2026-08-10 05:27:03.589931
851	120	3	28.650	\N	2026-08-10 05:27:03.589931
852	120	4	26.800	\N	2026-08-10 05:27:03.589931
853	120	5	21.250	\N	2026-08-10 05:27:03.589931
854	120	6	23.500	\N	2026-08-10 05:27:03.589931
855	120	7	25.850	\N	2026-08-10 05:27:03.589931
856	120	8	26.750	\N	2026-08-10 05:27:03.589931
857	121	1	27.900	\N	2026-08-10 05:28:03.324527
858	121	2	28.100	\N	2026-08-10 05:28:03.324527
859	121	3	28.850	\N	2026-08-10 05:28:03.324527
860	121	4	28.100	\N	2026-08-10 05:28:03.324527
861	121	5	29.150	\N	2026-08-10 05:28:03.324527
862	121	6	28.100	\N	2026-08-10 05:28:03.324527
863	121	7	28.650	\N	2026-08-10 05:28:03.324527
864	121	8	28.300	\N	2026-08-10 05:28:03.324527
865	122	1	27.450	\N	2026-08-10 05:28:46.604898
866	122	2	27.050	\N	2026-08-10 05:28:46.604898
867	122	3	32.100	\N	2026-08-10 05:28:46.604898
868	123	1	33.750	\N	2026-08-10 05:30:46.537843
869	123	2	30.250	\N	2026-08-10 05:30:46.537843
870	123	3	27.250	\N	2026-08-10 05:30:46.537843
871	123	4	27.300	\N	2026-08-10 05:30:46.537843
872	123	5	27.200	\N	2026-08-10 05:30:46.537843
873	123	6	28.250	\N	2026-08-10 05:30:46.537843
874	123	7	25.800	\N	2026-08-10 05:30:46.537843
875	123	8	27.250	\N	2026-08-10 05:30:46.537843
876	123	9	27.350	\N	2026-08-10 05:30:46.537843
884	125	1	25.900	\N	2026-08-10 05:33:23.641765
885	125	2	26.600	\N	2026-08-10 05:33:23.641765
886	125	3	25.000	\N	2026-08-10 05:33:23.641765
887	125	4	26.600	\N	2026-08-10 05:33:23.641765
888	125	5	26.850	\N	2026-08-10 05:33:23.641765
889	125	6	28.200	\N	2026-08-10 05:33:23.641765
890	125	7	25.150	\N	2026-08-10 05:33:23.641765
891	125	8	27.700	\N	2026-08-10 05:33:23.641765
892	124	1	24.600	\N	2026-08-10 05:34:55.986537
893	124	2	26.650	\N	2026-08-10 05:34:55.986537
894	124	3	24.300	\N	2026-08-10 05:34:55.986537
895	124	4	23.900	\N	2026-08-10 05:34:55.986537
896	124	5	25.050	\N	2026-08-10 05:34:55.986537
897	124	6	23.100	\N	2026-08-10 05:34:55.986537
898	124	7	25.650	\N	2026-08-10 05:34:55.986537
899	126	1	28.800	\N	2026-08-11 05:24:27.73266
900	126	2	28.150	\N	2026-08-11 05:24:27.73266
901	126	3	30.000	\N	2026-08-11 05:24:27.73266
902	126	4	23.550	\N	2026-08-11 05:24:27.73266
903	126	5	27.300	\N	2026-08-11 05:24:27.73266
904	127	1	29.550	\N	2026-08-11 05:26:47.336666
905	127	2	27.650	\N	2026-08-11 05:26:47.336666
906	127	3	29.200	\N	2026-08-11 05:26:47.336666
907	127	4	29.450	\N	2026-08-11 05:26:47.336666
908	127	5	29.650	\N	2026-08-11 05:26:47.336666
909	127	6	29.550	\N	2026-08-11 05:26:47.336666
910	128	1	27.350	\N	2026-08-11 05:31:19.677755
911	128	2	27.100	\N	2026-08-11 05:31:19.677755
912	128	3	29.550	\N	2026-08-11 05:31:19.677755
913	128	4	29.050	\N	2026-08-11 05:31:19.677755
914	128	5	25.450	\N	2026-08-11 05:31:19.677755
915	128	6	21.700	\N	2026-08-11 05:31:19.677755
916	128	7	28.100	\N	2026-08-11 05:31:19.677755
917	128	8	28.200	\N	2026-08-11 05:31:19.677755
918	128	9	18.350	\N	2026-08-11 05:31:19.677755
919	129	1	24.050	\N	2026-08-11 05:36:02.008856
920	129	2	22.450	\N	2026-08-11 05:36:02.008856
921	129	3	19.950	\N	2026-08-11 05:36:02.008856
922	129	4	25.250	\N	2026-08-11 05:36:02.008856
923	129	5	16.250	\N	2026-08-11 05:36:02.008856
924	129	6	11.950	\N	2026-08-11 05:36:02.008856
925	129	7	23.600	\N	2026-08-11 05:36:02.008856
926	130	1	28.500	\N	2026-08-11 05:36:52.435471
927	130	2	28.600	\N	2026-08-11 05:36:52.435471
928	130	3	23.000	\N	2026-08-11 05:36:52.435471
929	130	4	28.100	\N	2026-08-11 05:36:52.435471
930	131	1	31.600	\N	2026-08-11 05:38:13.686446
931	131	2	26.100	\N	2026-08-11 05:38:13.686446
932	131	3	28.500	\N	2026-08-11 05:38:13.686446
933	131	4	33.950	\N	2026-08-11 05:38:13.686446
934	131	5	27.400	\N	2026-08-11 05:38:13.686446
935	131	6	27.350	\N	2026-08-11 05:38:13.686446
936	131	7	29.100	\N	2026-08-11 05:38:13.686446
937	131	8	28.250	\N	2026-08-11 05:38:13.686446
938	132	1	27.050	\N	2026-08-11 05:39:17.78189
939	132	2	23.750	\N	2026-08-11 05:39:17.78189
940	132	3	27.400	\N	2026-08-11 05:39:17.78189
941	132	4	27.200	\N	2026-08-11 05:39:17.78189
942	132	5	27.750	\N	2026-08-11 05:39:17.78189
943	132	6	27.150	\N	2026-08-11 05:39:17.78189
944	132	7	27.250	\N	2026-08-11 05:39:17.78189
945	132	8	27.450	\N	2026-08-11 05:39:17.78189
946	132	9	27.200	\N	2026-08-11 05:39:17.78189
947	132	10	29.100	\N	2026-08-11 05:39:17.78189
948	133	1	16.800	\N	2026-08-11 05:40:14.148997
949	133	2	27.400	\N	2026-08-11 05:40:14.148997
950	133	3	26.250	\N	2026-08-11 05:40:14.148997
951	133	4	27.450	\N	2026-08-11 05:40:14.148997
952	133	5	27.850	\N	2026-08-11 05:40:14.148997
953	133	6	25.800	\N	2026-08-11 05:40:14.148997
954	133	7	29.500	\N	2026-08-11 05:40:14.148997
955	133	8	28.600	\N	2026-08-11 05:40:14.148997
956	133	9	28.450	\N	2026-08-11 05:40:14.148997
957	134	1	33.200	\N	2026-08-11 05:42:02.246542
958	134	2	30.250	\N	2026-08-11 05:42:02.246542
959	134	3	28.050	\N	2026-08-11 05:42:02.246542
960	135	1	29.050	\N	2026-08-12 05:14:43.470644
961	135	2	29.350	\N	2026-08-12 05:14:43.470644
962	135	3	28.200	\N	2026-08-12 05:14:43.470644
963	135	4	29.050	\N	2026-08-12 05:14:43.470644
964	135	5	28.850	\N	2026-08-12 05:14:43.470644
965	135	6	28.200	\N	2026-08-12 05:14:43.470644
966	135	7	28.850	\N	2026-08-12 05:14:43.470644
967	135	8	27.350	\N	2026-08-12 05:14:43.470644
968	136	1	27.750	\N	2026-08-12 05:16:36.540058
969	136	2	28.950	\N	2026-08-12 05:16:36.540058
970	136	3	29.850	\N	2026-08-12 05:16:36.540058
971	136	4	27.250	\N	2026-08-12 05:16:36.540058
972	136	5	27.500	\N	2026-08-12 05:16:36.540058
973	136	6	27.150	\N	2026-08-12 05:16:36.540058
974	136	7	27.450	\N	2026-08-12 05:16:36.540058
975	136	8	27.500	\N	2026-08-12 05:16:36.540058
976	136	9	32.850	\N	2026-08-12 05:16:36.540058
977	136	10	28.500	\N	2026-08-12 05:16:36.540058
978	137	1	27.450	\N	2026-08-12 05:19:50.744193
979	137	2	28.150	\N	2026-08-12 05:19:50.744193
980	137	3	27.350	\N	2026-08-12 05:19:50.744193
981	137	4	24.000	\N	2026-08-12 05:19:50.744193
982	137	5	27.350	\N	2026-08-12 05:19:50.744193
983	137	6	27.300	\N	2026-08-12 05:19:50.744193
984	137	7	27.250	\N	2026-08-12 05:19:50.744193
985	137	8	27.300	\N	2026-08-12 05:19:50.744193
986	137	9	27.650	\N	2026-08-12 05:19:50.744193
987	137	10	28.200	\N	2026-08-12 05:19:50.744193
988	138	1	26.900	\N	2026-08-12 05:20:38.332118
989	138	2	25.800	\N	2026-08-12 05:20:38.332118
990	138	3	25.400	\N	2026-08-12 05:20:38.332118
991	138	4	28.950	\N	2026-08-12 05:20:38.332118
992	138	5	23.050	\N	2026-08-12 05:20:38.332118
993	139	1	32.900	\N	2026-08-12 05:21:17.214757
994	139	2	27.450	\N	2026-08-12 05:21:17.214757
995	139	3	28.250	\N	2026-08-12 05:21:17.214757
996	139	4	28.050	\N	2026-08-12 05:21:17.214757
997	140	1	16.350	\N	2026-08-12 05:22:39.016676
998	140	2	17.300	\N	2026-08-12 05:22:39.016676
999	141	1	16.750	\N	2026-08-12 05:23:29.048664
1218	171	1	30.550	\N	2026-08-16 07:18:54.385539
1219	171	2	29.700	\N	2026-08-16 07:18:54.385539
1220	171	3	30.350	\N	2026-08-16 07:18:54.385539
1221	171	4	30.550	\N	2026-08-16 07:18:54.385539
1222	171	5	26.300	\N	2026-08-16 07:18:54.385539
1223	171	6	28.600	\N	2026-08-16 07:18:54.385539
1251	175	6	24.450	\N	2026-08-16 07:24:50.375929
1252	175	7	23.400	\N	2026-08-16 07:24:50.375929
1253	175	8	23.800	\N	2026-08-16 07:24:50.375929
1009	143	1	21.550	\N	2026-08-12 05:25:55.225812
1010	143	2	24.100	\N	2026-08-12 05:25:55.225812
1011	143	3	34.250	\N	2026-08-12 05:25:55.225812
1012	143	4	27.400	\N	2026-08-12 05:25:55.225812
1013	143	5	27.400	\N	2026-08-12 05:25:55.225812
1014	143	6	27.550	\N	2026-08-12 05:25:55.225812
1015	143	7	29.050	\N	2026-08-12 05:25:55.225812
1016	143	8	27.350	\N	2026-08-12 05:25:55.225812
1017	143	9	27.350	\N	2026-08-12 05:25:55.225812
1018	143	10	26.500	\N	2026-08-12 05:25:55.225812
1019	143	11	28.000	\N	2026-08-12 05:25:55.225812
1020	144	1	21.700	\N	2026-08-12 05:28:07.246176
1021	144	2	16.250	\N	2026-08-12 05:28:07.246176
1022	144	3	28.150	\N	2026-08-12 05:28:07.246176
1023	144	4	27.000	\N	2026-08-12 05:28:07.246176
1024	144	5	25.750	\N	2026-08-12 05:28:07.246176
1025	144	6	27.300	\N	2026-08-12 05:28:07.246176
1026	144	7	27.350	\N	2026-08-12 05:28:07.246176
1027	144	8	27.350	\N	2026-08-12 05:28:07.246176
1028	144	9	29.000	\N	2026-08-12 05:28:07.246176
1029	144	10	28.500	\N	2026-08-12 05:28:07.246176
1030	145	1	20.500	\N	2026-08-12 05:28:46.41942
1031	145	2	30.000	\N	2026-08-12 05:28:46.41942
1032	145	3	30.950	\N	2026-08-12 05:28:46.41942
1033	145	4	31.950	\N	2026-08-12 05:28:46.41942
1034	145	5	28.600	\N	2026-08-12 05:28:46.41942
1035	146	1	23.950	\N	2026-08-12 05:29:39.113399
1036	146	2	29.650	\N	2026-08-12 05:29:39.113399
1037	146	3	28.750	\N	2026-08-12 05:29:39.113399
1038	146	4	32.100	\N	2026-08-12 05:29:39.113399
1039	146	5	31.200	\N	2026-08-12 05:29:39.113399
1040	146	6	35.400	\N	2026-08-12 05:29:39.113399
1041	146	7	30.200	\N	2026-08-12 05:29:39.113399
1042	147	1	27.100	\N	2026-08-12 05:30:31.757677
1043	147	2	28.800	\N	2026-08-12 05:30:31.757677
1044	147	3	27.450	\N	2026-08-12 05:30:31.757677
1224	172	1	26.850	\N	2026-08-16 07:19:35.018273
1225	172	2	27.500	\N	2026-08-16 07:19:35.018273
1226	172	3	26.550	\N	2026-08-16 07:19:35.018273
1227	172	4	22.500	\N	2026-08-16 07:19:35.018273
1063	142	1	18.700	\N	2026-08-12 07:30:10.010366
1064	142	2	22.550	\N	2026-08-12 07:30:10.010366
1065	142	3	25.700	\N	2026-08-12 07:30:10.010366
1066	142	4	34.200	\N	2026-08-12 07:30:10.010366
1067	142	5	29.250	\N	2026-08-12 07:30:10.010366
1068	142	6	27.500	\N	2026-08-12 07:30:10.010366
1069	142	7	27.450	\N	2026-08-12 07:30:10.010366
1070	142	8	27.450	\N	2026-08-12 07:30:10.010366
1071	142	9	29.000	\N	2026-08-12 07:30:10.010366
1072	148	1	27.750	\N	2026-08-13 04:43:22.223796
1073	148	2	29.450	\N	2026-08-13 04:43:22.223796
1074	148	3	29.300	\N	2026-08-13 04:43:22.223796
1075	148	4	28.400	\N	2026-08-13 04:43:22.223796
1076	148	5	28.950	\N	2026-08-13 04:43:22.223796
1077	148	6	28.900	\N	2026-08-13 04:43:22.223796
1078	148	7	28.250	\N	2026-08-13 04:43:22.223796
1079	148	8	23.000	\N	2026-08-13 04:43:22.223796
1080	149	1	31.000	\N	2026-08-13 04:44:35.224753
1081	149	2	30.200	\N	2026-08-13 04:44:35.224753
1082	149	3	29.500	\N	2026-08-13 04:44:35.224753
1083	149	4	29.600	\N	2026-08-13 04:44:35.224753
1084	149	5	31.150	\N	2026-08-13 04:44:35.224753
1085	149	6	31.200	\N	2026-08-13 04:44:35.224753
1086	149	7	31.200	\N	2026-08-13 04:44:35.224753
1087	149	8	31.100	\N	2026-08-13 04:44:35.224753
1088	149	9	31.400	\N	2026-08-13 04:44:35.224753
1089	150	1	31.250	\N	2026-08-13 04:45:34.228718
1090	150	2	30.350	\N	2026-08-13 04:45:34.228718
1091	150	3	29.450	\N	2026-08-13 04:45:34.228718
1092	150	4	31.250	\N	2026-08-13 04:45:34.228718
1093	150	5	31.200	\N	2026-08-13 04:45:34.228718
1094	150	6	31.000	\N	2026-08-13 04:45:34.228718
1095	150	7	31.150	\N	2026-08-13 04:45:34.228718
1096	150	8	22.250	\N	2026-08-13 04:45:34.228718
1097	150	9	27.550	\N	2026-08-13 04:45:34.228718
1098	151	1	22.450	\N	2026-08-13 04:46:21.136222
1099	151	2	30.250	\N	2026-08-13 04:46:21.136222
1100	151	3	24.800	\N	2026-08-13 04:46:21.136222
1101	151	4	28.100	\N	2026-08-13 04:46:21.136222
1102	151	5	30.100	\N	2026-08-13 04:46:21.136222
1103	151	6	23.700	\N	2026-08-13 04:46:21.136222
1108	153	1	27.600	\N	2026-08-13 04:48:05.77479
1109	153	2	27.400	\N	2026-08-13 04:48:05.77479
1110	153	3	26.700	\N	2026-08-13 04:48:05.77479
1111	153	4	29.200	\N	2026-08-13 04:48:05.77479
1112	153	5	14.000	\N	2026-08-13 04:48:05.77479
1113	153	6	28.900	\N	2026-08-13 04:48:05.77479
1114	153	7	29.400	\N	2026-08-13 04:48:05.77479
1115	154	1	27.900	\N	2026-08-13 04:49:14.216822
1116	154	2	27.450	\N	2026-08-13 04:49:14.216822
1117	154	3	28.250	\N	2026-08-13 04:49:14.216822
1118	154	4	26.400	\N	2026-08-13 04:49:14.216822
1119	154	5	27.650	\N	2026-08-13 04:49:14.216822
1120	155	1	19.800	\N	2026-08-13 04:50:17.260845
1121	155	2	29.800	\N	2026-08-13 04:50:17.260845
1122	155	3	30.550	\N	2026-08-13 04:50:17.260845
1123	155	4	28.400	\N	2026-08-13 04:50:17.260845
1124	155	5	31.000	\N	2026-08-13 04:50:17.260845
1125	155	6	29.600	\N	2026-08-13 04:50:17.260845
1126	155	7	31.600	\N	2026-08-13 04:50:17.260845
1127	155	8	29.200	\N	2026-08-13 04:50:17.260845
1128	156	1	27.350	\N	2026-08-13 04:51:23.964216
1129	156	2	29.700	\N	2026-08-13 04:51:23.964216
1130	156	3	24.500	\N	2026-08-13 04:51:23.964216
1131	156	4	29.800	\N	2026-08-13 04:51:23.964216
1132	156	5	25.050	\N	2026-08-13 04:51:23.964216
1133	156	6	29.300	\N	2026-08-13 04:51:23.964216
1134	156	7	25.050	\N	2026-08-13 04:51:23.964216
1135	156	8	33.400	\N	2026-08-13 04:51:23.964216
1136	156	9	25.900	\N	2026-08-13 04:51:23.964216
1137	156	10	19.650	\N	2026-08-13 04:51:23.964216
1138	152	1	26.700	\N	2026-08-15 05:54:52.425583
1139	152	2	9.350	\N	2026-08-15 05:54:52.425583
1140	152	3	24.850	\N	2026-08-15 05:54:52.425583
1141	152	4	25.050	\N	2026-08-15 05:54:52.425583
1142	157	1	19.100	\N	2026-08-15 05:57:47.128772
1143	158	1	27.900	\N	2026-08-15 06:02:43.362655
1144	159	1	29.700	\N	2026-08-15 06:03:48.665526
1145	159	2	32.200	\N	2026-08-15 06:03:48.665526
1146	159	3	28.000	\N	2026-08-15 06:03:48.665526
1147	159	4	27.650	\N	2026-08-15 06:03:48.665526
1148	159	5	28.950	\N	2026-08-15 06:03:48.665526
1149	159	6	28.800	\N	2026-08-15 06:03:48.665526
1150	159	7	29.600	\N	2026-08-15 06:03:48.665526
1151	160	1	30.500	\N	2026-08-15 06:04:23.470122
1152	160	2	21.900	\N	2026-08-15 06:04:23.470122
1153	161	1	30.700	\N	2026-08-15 06:06:26.1927
1154	161	2	21.100	\N	2026-08-15 06:06:26.1927
1155	161	3	25.900	\N	2026-08-15 06:06:26.1927
1156	161	4	26.200	\N	2026-08-15 06:06:26.1927
1157	161	5	27.350	\N	2026-08-15 06:06:26.1927
1158	161	6	28.300	\N	2026-08-15 06:06:26.1927
1159	161	7	26.800	\N	2026-08-15 06:06:26.1927
1160	161	8	27.450	\N	2026-08-15 06:06:26.1927
1161	162	1	20.650	\N	2026-08-15 06:07:04.277791
1162	163	1	27.250	\N	2026-08-15 06:08:05.670254
1163	163	2	25.400	\N	2026-08-15 06:08:05.670254
1164	163	3	31.050	\N	2026-08-15 06:08:05.670254
1165	163	4	31.050	\N	2026-08-15 06:08:05.670254
1166	163	5	27.100	\N	2026-08-15 06:08:05.670254
1167	163	6	26.400	\N	2026-08-15 06:08:05.670254
1168	163	7	25.950	\N	2026-08-15 06:08:05.670254
1169	163	8	27.250	\N	2026-08-15 06:08:05.670254
1170	163	9	27.600	\N	2026-08-15 06:08:05.670254
1171	164	1	25.300	\N	2026-08-15 06:08:57.221169
1172	164	2	24.650	\N	2026-08-15 06:08:57.221169
1173	164	3	25.700	\N	2026-08-15 06:08:57.221169
1174	164	4	27.150	\N	2026-08-15 06:08:57.221169
1175	164	5	27.200	\N	2026-08-15 06:08:57.221169
1176	164	6	26.800	\N	2026-08-15 06:08:57.221169
1177	164	7	27.200	\N	2026-08-15 06:08:57.221169
1178	164	8	26.550	\N	2026-08-15 06:08:57.221169
1179	164	9	28.500	\N	2026-08-15 06:08:57.221169
1180	165	1	18.650	\N	2026-08-15 06:09:52.093661
1181	165	2	28.350	\N	2026-08-15 06:09:52.093661
1182	165	3	29.550	\N	2026-08-15 06:09:52.093661
1183	165	4	27.900	\N	2026-08-15 06:09:52.093661
1184	165	5	27.900	\N	2026-08-15 06:09:52.093661
1185	165	6	29.000	\N	2026-08-15 06:09:52.093661
1186	165	7	31.200	\N	2026-08-15 06:09:52.093661
1187	166	1	20.650	\N	2026-08-15 06:11:02.348358
1188	166	2	30.150	\N	2026-08-15 06:11:02.348358
1189	166	3	30.800	\N	2026-08-15 06:11:02.348358
1190	166	4	29.800	\N	2026-08-15 06:11:02.348358
1191	166	5	30.100	\N	2026-08-15 06:11:02.348358
1192	166	6	30.350	\N	2026-08-15 06:11:02.348358
1193	166	7	31.750	\N	2026-08-15 06:11:02.348358
1272	178	6	28.900	\N	2026-08-17 05:21:35.499855
1273	178	7	28.650	\N	2026-08-17 05:21:35.499855
1274	178	8	28.350	\N	2026-08-17 05:21:35.499855
1275	179	1	28.150	\N	2026-08-17 05:22:36.693698
1276	179	2	26.750	\N	2026-08-17 05:22:36.693698
1277	179	3	28.300	\N	2026-08-17 05:22:36.693698
1278	179	4	26.800	\N	2026-08-17 05:22:36.693698
1279	179	5	28.450	\N	2026-08-17 05:22:36.693698
1280	179	6	27.250	\N	2026-08-17 05:22:36.693698
1281	179	7	28.350	\N	2026-08-17 05:22:36.693698
1282	179	8	26.750	\N	2026-08-17 05:22:36.693698
1283	180	1	27.550	\N	2026-08-17 05:23:30.453518
1284	180	2	24.200	\N	2026-08-17 05:23:30.453518
1285	180	3	16.000	\N	2026-08-17 05:23:30.453518
1286	180	4	13.100	\N	2026-08-17 05:23:30.453518
1287	180	5	26.200	\N	2026-08-17 05:23:30.453518
1288	180	6	28.300	\N	2026-08-17 05:23:30.453518
1289	180	7	25.450	\N	2026-08-17 05:23:30.453518
1290	181	1	24.550	\N	2026-08-17 05:24:23.26763
1291	181	2	22.100	\N	2026-08-17 05:24:23.26763
1292	181	3	25.900	\N	2026-08-17 05:24:23.26763
1293	181	4	22.700	\N	2026-08-17 05:24:23.26763
1294	181	5	26.800	\N	2026-08-17 05:24:23.26763
1295	181	6	27.350	\N	2026-08-17 05:24:23.26763
1296	182	1	26.150	\N	2026-08-17 05:25:28.201228
1297	182	2	28.250	\N	2026-08-17 05:25:28.201228
1298	182	3	26.400	\N	2026-08-17 05:25:28.201228
1299	182	4	26.900	\N	2026-08-17 05:25:28.201228
1300	182	5	28.250	\N	2026-08-17 05:25:28.201228
1301	182	6	29.750	\N	2026-08-17 05:25:28.201228
1302	182	7	26.100	\N	2026-08-17 05:25:28.201228
1303	182	8	27.000	\N	2026-08-17 05:25:28.201228
1304	182	9	25.200	\N	2026-08-17 05:25:28.201228
1305	183	1	22.650	\N	2026-08-17 05:26:31.576617
1306	183	2	26.800	\N	2026-08-17 05:26:31.576617
1307	183	3	26.850	\N	2026-08-17 05:26:31.576617
1308	183	4	26.450	\N	2026-08-17 05:26:31.576617
1309	183	5	27.550	\N	2026-08-17 05:26:31.576617
1310	183	6	26.050	\N	2026-08-17 05:26:31.576617
1311	183	7	28.450	\N	2026-08-17 05:26:31.576617
1312	183	8	25.250	\N	2026-08-17 05:26:31.576617
1313	183	9	26.750	\N	2026-08-17 05:26:31.576617
1314	184	1	32.350	\N	2026-08-17 05:27:33.906173
1315	184	2	29.200	\N	2026-08-17 05:27:33.906173
1316	184	3	28.100	\N	2026-08-17 05:27:33.906173
1317	184	4	28.600	\N	2026-08-17 05:27:33.906173
1318	184	5	29.400	\N	2026-08-17 05:27:33.906173
1319	184	6	27.250	\N	2026-08-17 05:27:33.906173
1320	184	7	31.850	\N	2026-08-17 05:27:33.906173
1321	185	1	23.800	\N	2026-08-17 05:28:25.149654
1322	185	2	28.800	\N	2026-08-17 05:28:25.149654
1323	185	3	23.850	\N	2026-08-17 05:28:25.149654
1324	185	4	20.200	\N	2026-08-17 05:28:25.149654
1325	185	5	19.400	\N	2026-08-17 05:28:25.149654
1326	185	6	22.450	\N	2026-08-17 05:28:25.149654
1327	185	7	22.100	\N	2026-08-17 05:28:25.149654
1337	173	1	31.400	\N	2026-08-17 12:59:49.124489
1338	173	2	31.400	\N	2026-08-17 12:59:49.124489
1339	173	3	25.450	\N	2026-08-17 12:59:49.124489
1340	173	4	26.100	\N	2026-08-17 12:59:49.124489
1341	173	5	25.850	\N	2026-08-17 12:59:49.124489
1342	173	6	27.150	\N	2026-08-17 12:59:49.124489
1343	173	7	27.150	\N	2026-08-17 12:59:49.124489
1344	173	8	25.600	\N	2026-08-17 12:59:49.124489
1345	173	9	27.750	\N	2026-08-17 12:59:49.124489
1346	186	1	26.600	\N	2026-08-18 04:52:31.321758
1347	186	2	21.900	\N	2026-08-18 04:52:31.321758
1348	186	3	28.250	\N	2026-08-18 04:52:31.321758
1349	186	4	27.250	\N	2026-08-18 04:52:31.321758
1350	186	5	27.950	\N	2026-08-18 04:52:31.321758
1351	186	6	26.700	\N	2026-08-18 04:52:31.321758
1352	186	7	29.150	\N	2026-08-18 04:52:31.321758
1353	186	8	29.700	\N	2026-08-18 04:52:31.321758
1354	186	9	25.650	\N	2026-08-18 04:52:31.321758
1355	187	1	27.100	\N	2026-08-18 04:53:36.119909
1356	187	2	26.650	\N	2026-08-18 04:53:36.119909
1357	187	3	27.000	\N	2026-08-18 04:53:36.119909
1358	187	4	24.600	\N	2026-08-18 04:53:36.119909
1359	187	5	27.150	\N	2026-08-18 04:53:36.119909
1360	187	6	26.400	\N	2026-08-18 04:53:36.119909
1361	187	7	25.450	\N	2026-08-18 04:53:36.119909
1362	187	8	26.500	\N	2026-08-18 04:53:36.119909
1363	187	9	20.950	\N	2026-08-18 04:53:36.119909
1364	188	1	25.450	\N	2026-08-18 04:54:41.341051
1365	188	2	26.850	\N	2026-08-18 04:54:41.341051
1366	188	3	26.650	\N	2026-08-18 04:54:41.341051
1367	188	4	24.950	\N	2026-08-18 04:54:41.341051
1368	188	5	22.250	\N	2026-08-18 04:54:41.341051
1369	188	6	25.800	\N	2026-08-18 04:54:41.341051
1370	188	7	23.700	\N	2026-08-18 04:54:41.341051
1371	188	8	19.400	\N	2026-08-18 04:54:41.341051
1372	189	1	21.000	\N	2026-08-18 04:55:37.622849
1373	189	2	19.250	\N	2026-08-18 04:55:37.622849
1374	189	3	22.500	\N	2026-08-18 04:55:37.622849
1375	189	4	21.850	\N	2026-08-18 04:55:37.622849
1376	189	5	21.300	\N	2026-08-18 04:55:37.622849
1377	189	6	19.850	\N	2026-08-18 04:55:37.622849
1378	189	7	23.000	\N	2026-08-18 04:55:37.622849
1379	189	8	18.350	\N	2026-08-18 04:55:37.622849
1380	190	1	24.450	\N	2026-08-18 04:56:56.733562
1381	190	2	27.000	\N	2026-08-18 04:56:56.733562
1382	190	3	25.450	\N	2026-08-18 04:56:56.733562
1383	190	4	26.650	\N	2026-08-18 04:56:56.733562
1384	190	5	26.150	\N	2026-08-18 04:56:56.733562
1385	190	6	27.700	\N	2026-08-18 04:56:56.733562
1386	190	7	26.700	\N	2026-08-18 04:56:56.733562
1387	190	8	25.700	\N	2026-08-18 04:56:56.733562
1388	190	9	27.000	\N	2026-08-18 04:56:56.733562
1389	191	1	19.450	\N	2026-08-18 04:58:03.260133
1390	191	2	27.150	\N	2026-08-18 04:58:03.260133
1391	191	3	26.050	\N	2026-08-18 04:58:03.260133
1392	191	4	26.200	\N	2026-08-18 04:58:03.260133
1393	191	5	25.450	\N	2026-08-18 04:58:03.260133
1394	191	6	28.150	\N	2026-08-18 04:58:03.260133
1395	191	7	28.200	\N	2026-08-18 04:58:03.260133
1396	191	8	26.700	\N	2026-08-18 04:58:03.260133
1397	191	9	27.500	\N	2026-08-18 04:58:03.260133
1398	192	1	25.900	\N	2026-08-18 04:59:14.986452
1399	192	2	30.300	\N	2026-08-18 04:59:14.986452
1400	192	3	28.650	\N	2026-08-18 04:59:14.986452
1401	192	4	30.450	\N	2026-08-18 04:59:14.986452
1402	192	5	29.700	\N	2026-08-18 04:59:14.986452
1403	192	6	31.200	\N	2026-08-18 04:59:14.986452
1404	193	1	21.100	\N	2026-08-18 05:00:05.173048
1405	193	2	23.000	\N	2026-08-18 05:00:05.173048
1406	193	3	20.400	\N	2026-08-18 05:00:05.173048
1407	193	4	26.500	\N	2026-08-18 05:00:05.173048
1408	193	5	23.400	\N	2026-08-18 05:00:05.173048
1409	193	6	22.650	\N	2026-08-18 05:00:05.173048
1410	193	7	23.750	\N	2026-08-18 05:00:05.173048
1411	194	1	27.450	\N	2026-08-19 04:14:15.119295
1412	194	2	25.150	\N	2026-08-19 04:14:15.119295
1413	194	3	26.900	\N	2026-08-19 04:14:15.119295
1414	194	4	27.750	\N	2026-08-19 04:14:15.119295
1415	194	5	27.300	\N	2026-08-19 04:14:15.119295
1416	194	6	27.550	\N	2026-08-19 04:14:15.119295
1417	194	7	27.650	\N	2026-08-19 04:14:15.119295
1418	194	8	27.850	\N	2026-08-19 04:14:15.119295
1419	194	9	29.200	\N	2026-08-19 04:14:15.119295
1420	195	1	25.150	\N	2026-08-19 04:18:39.081607
1421	195	2	24.900	\N	2026-08-19 04:18:39.081607
1422	195	3	25.200	\N	2026-08-19 04:18:39.081607
1423	195	4	27.800	\N	2026-08-19 04:18:39.081607
1424	195	5	25.000	\N	2026-08-19 04:18:39.081607
1425	195	6	23.000	\N	2026-08-19 04:18:39.081607
1426	195	7	28.100	\N	2026-08-19 04:18:39.081607
1427	195	8	26.750	\N	2026-08-19 04:18:39.081607
1428	195	9	27.350	\N	2026-08-19 04:18:39.081607
1429	196	1	23.400	\N	2026-08-19 04:19:23.905054
1430	196	2	24.650	\N	2026-08-19 04:19:23.905054
1431	196	3	24.700	\N	2026-08-19 04:19:23.905054
1432	196	4	25.700	\N	2026-08-19 04:19:23.905054
1433	196	5	24.850	\N	2026-08-19 04:19:23.905054
1434	197	1	20.850	\N	2026-08-19 04:19:54.187297
1435	197	2	18.000	\N	2026-08-19 04:19:54.187297
1436	198	1	24.600	\N	2026-08-19 04:20:43.446799
1437	198	2	28.750	\N	2026-08-19 04:20:43.446799
1438	198	3	27.000	\N	2026-08-19 04:20:43.446799
1439	198	4	28.650	\N	2026-08-19 04:20:43.446799
1440	198	5	26.800	\N	2026-08-19 04:20:43.446799
1441	198	6	28.550	\N	2026-08-19 04:20:43.446799
1442	198	7	24.650	\N	2026-08-19 04:20:43.446799
1443	199	1	23.500	\N	2026-08-19 04:21:41.522123
1444	199	2	26.450	\N	2026-08-19 04:21:41.522123
1445	199	3	20.550	\N	2026-08-19 04:21:41.522123
1446	199	4	22.800	\N	2026-08-19 04:21:41.522123
1447	199	5	22.700	\N	2026-08-19 04:21:41.522123
1448	199	6	22.800	\N	2026-08-19 04:21:41.522123
1449	199	7	24.850	\N	2026-08-19 04:21:41.522123
1450	200	1	25.400	\N	2026-08-19 04:22:41.562026
1451	200	2	26.850	\N	2026-08-19 04:22:41.562026
1452	200	3	25.550	\N	2026-08-19 04:22:41.562026
1453	200	4	27.900	\N	2026-08-19 04:22:41.562026
1454	200	5	25.500	\N	2026-08-19 04:22:41.562026
1455	200	6	25.300	\N	2026-08-19 04:22:41.562026
1456	200	7	26.600	\N	2026-08-19 04:22:41.562026
1457	200	8	30.050	\N	2026-08-19 04:22:41.562026
1458	200	9	26.550	\N	2026-08-19 04:22:41.562026
1459	201	1	25.150	\N	2026-08-19 04:23:38.595844
1460	201	2	19.650	\N	2026-08-19 04:23:38.595844
1461	201	3	25.600	\N	2026-08-19 04:23:38.595844
1462	201	4	26.200	\N	2026-08-19 04:23:38.595844
1463	201	5	25.550	\N	2026-08-19 04:23:38.595844
1464	201	6	27.700	\N	2026-08-19 04:23:38.595844
1465	201	7	27.100	\N	2026-08-19 04:23:38.595844
1466	201	8	26.400	\N	2026-08-19 04:23:38.595844
1467	201	9	28.200	\N	2026-08-19 04:23:38.595844
1468	202	1	28.050	\N	2026-08-19 04:24:34.972893
1469	202	2	30.200	\N	2026-08-19 04:24:34.972893
1470	202	3	30.700	\N	2026-08-19 04:24:34.972893
1471	202	4	29.400	\N	2026-08-19 04:24:34.972893
1472	202	5	30.800	\N	2026-08-19 04:24:34.972893
1473	202	6	31.250	\N	2026-08-19 04:24:34.972893
1474	202	7	26.550	\N	2026-08-19 04:24:34.972893
1475	203	1	25.650	\N	2026-08-19 04:25:30.946876
1476	203	2	28.950	\N	2026-08-19 04:25:30.946876
1477	203	3	22.050	\N	2026-08-19 04:25:30.946876
1478	203	4	22.000	\N	2026-08-19 04:25:30.946876
1479	203	5	23.600	\N	2026-08-19 04:25:30.946876
1480	203	6	26.750	\N	2026-08-19 04:25:30.946876
1481	203	7	24.550	\N	2026-08-19 04:25:30.946876
\.


--
-- Data for Name: daily_production_header; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_production_header (id, production_date, machine_id, employee_id, party_id, shift, status, remarks, created_by, created_at, updated_by, updated_at, reconciled, reconciled_transaction_id, reconciled_at) FROM stdin;
55	2026-08-04	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-05 05:21:33.592011	Iftikhar	2026-08-06 10:19:47.34	t	147	2026-08-06 10:29:27.695
59	2026-08-04	23	2	13	Night	submitted	\N	Iftikhar	2026-08-05 05:26:18.500287	\N	2026-08-05 05:26:18.500287	t	147	2026-08-06 10:29:27.695
54	2026-08-04	18	7	16	Morning	submitted	\N	Iftikhar	2026-08-05 05:20:10.782671	\N	2026-08-05 05:20:10.782671	t	148	2026-08-06 10:31:01.798
53	2026-08-04	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-05 05:19:28.381793	\N	2026-08-05 05:19:28.381793	t	150	2026-08-06 13:26:01.721
56	2026-08-04	25	9	14	Night	submitted	\N	Iftikhar	2026-08-05 05:22:54.381768	\N	2026-08-05 05:22:54.381768	t	150	2026-08-06 13:26:01.721
57	2026-08-04	14	9	14	Night	submitted	\N	Iftikhar	2026-08-05 05:23:56.914664	\N	2026-08-05 05:23:56.914664	t	150	2026-08-06 13:26:01.721
7	2026-08-01	18	7	17	Morning	submitted	\N	Iftikhar	2026-08-04 09:20:23.329666	\N	2026-08-04 09:20:23.329666	t	135	2026-08-04 13:14:03.613
15	2026-08-01	18	2	17	Night	submitted	\N	Iftikhar	2026-08-04 09:40:48.902839	\N	2026-08-04 09:40:48.902839	t	135	2026-08-04 13:14:03.613
58	2026-08-04	15	2	14	Night	submitted	\N	Iftikhar	2026-08-05 05:25:07.609832	\N	2026-08-05 05:25:07.609832	t	150	2026-08-06 13:26:01.721
60	2026-08-05	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-06 05:12:09.379561	\N	2026-08-06 05:12:09.379561	t	\N	2026-08-06 10:06:16.658
61	2026-08-05	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-06 05:13:41.179759	\N	2026-08-06 05:13:41.179759	t	\N	2026-08-06 10:06:16.658
62	2026-08-05	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-06 05:14:54.170255	\N	2026-08-06 05:14:54.170255	t	\N	2026-08-06 10:06:16.658
66	2026-08-05	14	9	14	Night	submitted	\N	Iftikhar	2026-08-06 05:21:03.119254	\N	2026-08-06 05:21:03.119254	t	\N	2026-08-06 10:06:16.658
20	2026-08-01	24	3	13	Night	submitted	\N	Iftikhar	2026-08-04 09:55:40.418218	abc	2026-08-07 12:32:39.043	t	139	2026-08-04 13:59:37.313
130	2026-08-10	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-11 05:36:52.435471	\N	2026-08-11 05:36:52.435471	t	197	2026-08-11 08:02:34.807
126	2026-08-10	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-11 05:24:27.73266	\N	2026-08-11 05:24:27.73266	t	198	2026-08-11 08:05:44.312
98	2026-07-31	25	18	13	Morning	submitted	\N	Hsn	2026-08-08 06:51:30.145466	\N	2026-08-08 06:51:30.145466	t	201	2026-08-12 09:30:15.429
104	2026-07-31	25	18	14	Morning	submitted	\N	Hsn	2026-08-08 07:31:28.848027	\N	2026-08-08 07:31:28.848027	t	202	2026-08-12 09:35:50.523
24	2026-08-02	18	7	16	Morning	submitted	\N	Iftikhar	2026-08-04 10:06:51.146146	\N	2026-08-04 10:06:51.146146	t	136	2026-08-04 13:17:25.823
102	2026-07-31	25	18	15	Morning	submitted	\N	Hsn	2026-08-08 07:07:33.221562	\N	2026-08-08 07:07:33.221562	t	206	2026-08-12 10:05:23.747
4	2026-08-01	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-04 09:10:42.87511	\N	2026-08-04 09:10:42.87511	t	132	2026-08-04 12:35:23.619
6	2026-08-01	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 09:18:31.354253	\N	2026-08-04 09:18:31.354253	t	132	2026-08-04 12:35:23.619
5	2026-08-01	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 09:16:42.696457	Iftikhar	2026-08-04 09:23:18.322	t	132	2026-08-04 12:35:23.619
12	2026-08-01	25	3	14	Night	submitted	\N	Iftikhar	2026-08-04 09:34:40.40951	\N	2026-08-04 09:34:40.40951	t	132	2026-08-04 12:35:23.619
13	2026-08-01	14	9	14	Night	submitted	\N	Iftikhar	2026-08-04 09:36:49.21394	\N	2026-08-04 09:36:49.21394	t	132	2026-08-04 12:35:23.619
14	2026-08-01	15	2	14	Night	submitted	\N	Iftikhar	2026-08-04 09:37:42.188473	\N	2026-08-04 09:37:42.188473	t	132	2026-08-04 12:35:23.619
21	2026-08-02	25	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 10:01:26.358251	\N	2026-08-04 10:01:26.358251	t	133	2026-08-04 12:43:09.691
22	2026-08-02	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 10:02:51.515396	\N	2026-08-04 10:02:51.515396	t	133	2026-08-04 12:43:09.691
23	2026-08-02	15	7	14	Morning	submitted	\N	Iftikhar	2026-08-04 10:03:57.20679	Iftikhar	2026-08-04 10:05:41.441	t	133	2026-08-04 12:43:09.691
29	2026-08-02	25	9	14	Night	submitted	\N	Iftikhar	2026-08-04 10:44:10.948865	\N	2026-08-04 10:44:10.948865	t	133	2026-08-04 12:43:09.691
31	2026-08-02	14	9	14	Night	submitted	\N	Iftikhar	2026-08-04 11:02:23.167923	\N	2026-08-04 11:02:23.167923	t	133	2026-08-04 12:43:09.691
32	2026-08-02	15	2	14	Night	submitted	\N	Iftikhar	2026-08-04 11:03:01.847261	\N	2026-08-04 11:03:01.847261	t	133	2026-08-04 12:43:09.691
38	2026-08-03	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-04 11:10:01.18467	\N	2026-08-04 11:10:01.18467	t	134	2026-08-04 13:06:18.972
39	2026-08-03	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 11:14:57.548808	\N	2026-08-04 11:14:57.548808	t	134	2026-08-04 13:06:18.972
40	2026-08-03	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 11:15:49.435534	\N	2026-08-04 11:15:49.435534	t	134	2026-08-04 13:06:18.972
45	2026-08-03	25	9	14	Night	submitted	\N	Iftikhar	2026-08-04 11:21:22.562363	\N	2026-08-04 11:21:22.562363	t	134	2026-08-04 13:06:18.972
46	2026-08-03	14	9	14	Night	submitted	\N	Iftikhar	2026-08-04 11:22:21.680401	\N	2026-08-04 11:22:21.680401	t	134	2026-08-04 13:06:18.972
47	2026-08-03	15	2	14	Night	submitted	\N	Iftikhar	2026-08-04 11:23:27.891391	\N	2026-08-04 11:23:27.891391	t	134	2026-08-04 13:06:18.972
25	2026-08-02	21	1	16	Morning	submitted	\N	Iftikhar	2026-08-04 10:07:59.206754	\N	2026-08-04 10:07:59.206754	t	136	2026-08-04 13:17:25.823
33	2026-08-02	18	2	16	Night	submitted	\N	Iftikhar	2026-08-04 11:04:36.849782	\N	2026-08-04 11:04:36.849782	t	136	2026-08-04 13:17:25.823
34	2026-08-02	21	9	16	Night	submitted	\N	Iftikhar	2026-08-04 11:05:46.793537	\N	2026-08-04 11:05:46.793537	t	136	2026-08-04 13:17:25.823
16	2026-08-01	18	2	20	Night	submitted	\N	Iftikhar	2026-08-04 09:41:28.654011	Iftikhar	2026-08-04 13:45:14.172	t	137	2026-08-04 13:53:44.511
8	2026-08-01	21	1	16	Morning	submitted	\N	Iftikhar	2026-08-04 09:25:40.653893	\N	2026-08-04 09:25:40.653893	t	138	2026-08-04 13:57:14.007
17	2026-08-01	21	9	16	Night	submitted	\N	Iftikhar	2026-08-04 09:45:30.288701	\N	2026-08-04 09:45:30.288701	t	138	2026-08-04 13:57:14.007
9	2026-08-01	22	8	13	Morning	submitted	\N	Iftikhar	2026-08-04 09:27:15.003235	\N	2026-08-04 09:27:15.003235	t	139	2026-08-04 13:59:37.313
10	2026-08-01	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-04 09:28:57.85111	\N	2026-08-04 09:28:57.85111	t	139	2026-08-04 13:59:37.313
18	2026-08-01	22	9	13	Night	submitted	\N	Iftikhar	2026-08-04 09:46:52.771207	\N	2026-08-04 09:46:52.771207	t	139	2026-08-04 13:59:37.313
19	2026-08-01	23	2	13	Night	submitted	\N	Iftikhar	2026-08-04 09:54:11.999346	\N	2026-08-04 09:54:11.999346	t	139	2026-08-04 13:59:37.313
11	2026-08-01	24	1	15	Morning	submitted	\N	Iftikhar	2026-08-04 09:30:40.700423	\N	2026-08-04 09:30:40.700423	t	140	2026-08-04 14:01:03.54
26	2026-08-02	22	8	13	Morning	submitted	\N	Iftikhar	2026-08-04 10:08:59.403701	\N	2026-08-04 10:08:59.403701	t	141	2026-08-04 14:03:06.842
27	2026-08-02	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-04 10:10:14.184358	\N	2026-08-04 10:10:14.184358	t	141	2026-08-04 14:03:06.842
35	2026-08-02	22	2	13	Night	submitted	\N	Iftikhar	2026-08-04 11:06:46.274667	\N	2026-08-04 11:06:46.274667	t	141	2026-08-04 14:03:06.842
36	2026-08-02	23	2	13	Night	submitted	\N	Iftikhar	2026-08-04 11:07:56.979945	\N	2026-08-04 11:07:56.979945	t	141	2026-08-04 14:03:06.842
28	2026-08-02	24	1	15	Morning	submitted	\N	Iftikhar	2026-08-04 10:11:18.644384	\N	2026-08-04 10:11:18.644384	t	142	2026-08-04 14:05:21.393
37	2026-08-02	24	9	15	Night	submitted	\N	Iftikhar	2026-08-04 11:08:47.644403	\N	2026-08-04 11:08:47.644403	t	142	2026-08-04 14:05:21.393
41	2026-08-03	18	7	16	Morning	submitted	\N	Iftikhar	2026-08-04 11:16:54.358067	\N	2026-08-04 11:16:54.358067	t	143	2026-08-04 14:07:52.264
42	2026-08-03	21	1	16	Morning	submitted	\N	Iftikhar	2026-08-04 11:18:01.178238	\N	2026-08-04 11:18:01.178238	t	143	2026-08-04 14:07:52.264
48	2026-08-03	18	2	16	Night	submitted	\N	Iftikhar	2026-08-04 11:24:21.364634	\N	2026-08-04 11:24:21.364634	t	143	2026-08-04 14:07:52.264
49	2026-08-03	21	9	16	Night	submitted	\N	Iftikhar	2026-08-04 11:25:27.95248	\N	2026-08-04 11:25:27.95248	t	143	2026-08-04 14:07:52.264
43	2026-08-03	22	8	13	Morning	submitted	\N	Iftikhar	2026-08-04 11:18:37.003406	\N	2026-08-04 11:18:37.003406	t	144	2026-08-04 14:10:05.393
44	2026-08-03	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-04 11:19:37.030411	\N	2026-08-04 11:19:37.030411	t	144	2026-08-04 14:10:05.393
50	2026-08-03	23	2	13	Night	submitted	\N	Iftikhar	2026-08-04 11:26:53.291837	\N	2026-08-04 11:26:53.291837	t	144	2026-08-04 14:10:05.393
64	2026-08-05	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-06 05:18:20.391739	\N	2026-08-06 05:18:20.391739	t	146	2026-08-06 10:08:54.843
68	2026-08-05	23	2	13	Night	submitted	\N	Iftikhar	2026-08-06 05:24:47.564861	\N	2026-08-06 05:24:47.564861	t	146	2026-08-06 10:08:54.843
69	2026-08-05	24	9	13	Night	submitted	\N	Iftikhar	2026-08-06 05:25:38.115455	\N	2026-08-06 05:25:38.115455	t	146	2026-08-06 10:08:54.843
63	2026-08-05	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-06 05:16:12.272644	Iftikhar	2026-08-06 09:50:06.528	t	146	2026-08-06 10:08:54.843
52	2026-08-04	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-05 05:18:12.192286	abc	2026-08-05 14:53:59.24	t	150	2026-08-06 13:26:01.721
51	2026-08-04	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-05 05:15:40.749114	abc	2026-08-05 23:02:26.29	t	150	2026-08-06 13:26:01.721
100	2026-07-31	25	18	16	Morning	submitted	\N	Hsn	2026-08-08 07:01:29.883679	\N	2026-08-08 07:01:29.883679	t	193	2026-08-11 06:59:11.495
99	2026-07-31	25	18	16	Morning	submitted	\N	Hsn	2026-08-08 06:58:00.950157	\N	2026-08-08 06:58:00.950157	t	193	2026-08-11 06:59:11.495
101	2026-07-31	25	18	16	Morning	submitted	\N	Hsn	2026-08-08 07:05:24.210104	\N	2026-08-08 07:05:24.210104	t	193	2026-08-11 06:59:11.495
129	2026-08-10	22	7	13	Morning	submitted	\N	Iftikhar	2026-08-11 05:36:02.008856	\N	2026-08-11 05:36:02.008856	t	197	2026-08-11 08:02:34.807
70	2026-08-06	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-07 05:23:01.634685	\N	2026-08-07 05:23:01.634685	t	153	2026-08-07 06:27:57.242
71	2026-08-06	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-07 05:25:39.804931	\N	2026-08-07 05:25:39.804931	t	153	2026-08-07 06:27:57.242
72	2026-08-06	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-07 05:26:45.829478	\N	2026-08-07 05:26:45.829478	t	153	2026-08-07 06:27:57.242
75	2026-08-06	25	9	14	Night	submitted	\N	Iftikhar	2026-08-07 05:29:56.839702	\N	2026-08-07 05:29:56.839702	t	153	2026-08-07 06:27:57.242
76	2026-08-06	14	2	14	Night	submitted	\N	Iftikhar	2026-08-07 05:31:51.762381	\N	2026-08-07 05:31:51.762381	t	153	2026-08-07 06:27:57.242
77	2026-08-06	15	2	14	Night	submitted	\N	Iftikhar	2026-08-07 05:33:08.312801	\N	2026-08-07 05:33:08.312801	t	153	2026-08-07 06:27:57.242
73	2026-08-06	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-07 05:27:39.547294	\N	2026-08-07 05:27:39.547294	t	154	2026-08-07 06:30:21.369
74	2026-08-06	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-07 05:28:49.295736	\N	2026-08-07 05:28:49.295736	t	154	2026-08-07 06:30:21.369
78	2026-08-06	23	2	13	Night	submitted	\N	Iftikhar	2026-08-07 05:34:13.840169	\N	2026-08-07 05:34:13.840169	t	154	2026-08-07 06:30:21.369
79	2026-08-06	24	9	13	Night	submitted	\N	Iftikhar	2026-08-07 05:35:10.784899	\N	2026-08-07 05:35:10.784899	t	154	2026-08-07 06:30:21.369
134	2026-08-10	22	2	13	Night	submitted	\N	Iftikhar	2026-08-11 05:42:02.246542	\N	2026-08-11 05:42:02.246542	t	197	2026-08-11 08:02:34.807
128	2026-08-10	15	7	14	Morning	submitted	\N	Iftikhar	2026-08-11 05:31:19.677755	\N	2026-08-11 05:31:19.677755	t	198	2026-08-11 08:05:44.312
127	2026-08-10	14	1	14	Morning	submitted	\N	Iftikhar	2026-08-11 05:26:47.336666	\N	2026-08-11 05:26:47.336666	t	198	2026-08-11 08:05:44.312
131	2026-08-10	25	9	14	Night	submitted	\N	Iftikhar	2026-08-11 05:38:13.686446	\N	2026-08-11 05:38:13.686446	t	198	2026-08-11 08:05:44.312
132	2026-08-10	14	9	14	Night	submitted	\N	Iftikhar	2026-08-11 05:39:17.78189	\N	2026-08-11 05:39:17.78189	t	198	2026-08-11 08:05:44.312
133	2026-08-10	15	2	14	Night	submitted	\N	Iftikhar	2026-08-11 05:40:14.148997	\N	2026-08-11 05:40:14.148997	t	198	2026-08-11 08:05:44.312
67	2026-08-05	15	2	14	Night	submitted	\N	Iftikhar	2026-08-06 05:23:48.398276	\N	2026-08-06 05:23:48.398276	t	\N	2026-08-06 10:06:16.658
65	2026-08-05	25	9	14	Night	submitted	\N	Iftikhar	2026-08-06 05:19:32.340692	Iftikhar	2026-08-06 05:26:52.716	t	\N	2026-08-06 10:06:16.658
135	2026-08-11	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-12 05:14:43.470644	\N	2026-08-12 05:14:43.470644	t	203	2026-08-12 09:41:16.297
138	2026-08-11	18	7	16	Morning	submitted	\N	Iftikhar	2026-08-12 05:20:38.332118	\N	2026-08-12 05:20:38.332118	t	204	2026-08-12 09:58:09.956
139	2026-08-11	19	7	16	Morning	submitted	\N	Iftikhar	2026-08-12 05:21:17.214757	\N	2026-08-12 05:21:17.214757	t	204	2026-08-12 09:58:09.956
140	2026-08-11	21	1	16	Morning	submitted	\N	Iftikhar	2026-08-12 05:22:39.016676	\N	2026-08-12 05:22:39.016676	t	204	2026-08-12 09:58:09.956
145	2026-08-11	18	2	16	Night	submitted	\N	Iftikhar	2026-08-12 05:28:46.41942	\N	2026-08-12 05:28:46.41942	t	204	2026-08-12 09:58:09.956
146	2026-08-11	19	2	16	Night	submitted	\N	Iftikhar	2026-08-12 05:29:39.113399	\N	2026-08-12 05:29:39.113399	t	204	2026-08-12 09:58:09.956
141	2026-08-11	22	7	13	Morning	submitted	\N	Iftikhar	2026-08-12 05:23:29.048664	\N	2026-08-12 05:23:29.048664	t	205	2026-08-12 10:00:37.816
103	2026-07-31	25	18	17	Morning	submitted	\N	Hsn	2026-08-08 07:12:47.109305	\N	2026-08-08 07:12:47.109305	t	207	2026-08-12 10:08:10.744
91	2026-08-07	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-08 05:37:33.883171	\N	2026-08-08 05:37:33.883171	t	166	2026-08-08 06:23:16.557
92	2026-08-07	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-08 05:39:02.666522	\N	2026-08-08 05:39:02.666522	t	166	2026-08-08 06:23:16.557
96	2026-08-07	23	2	13	Night	submitted	\N	Iftikhar	2026-08-08 05:44:27.618161	\N	2026-08-08 05:44:27.618161	t	166	2026-08-08 06:23:16.557
97	2026-08-07	24	9	13	Night	submitted	\N	Iftikhar	2026-08-08 05:45:15.246474	\N	2026-08-08 05:45:15.246474	t	166	2026-08-08 06:23:16.557
88	2026-08-07	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-08 05:33:43.300283	\N	2026-08-08 05:33:43.300283	t	167	2026-08-08 06:25:49.267
89	2026-08-07	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-08 05:34:49.051626	\N	2026-08-08 05:34:49.051626	t	167	2026-08-08 06:25:49.267
90	2026-08-07	15	7	14	Morning	submitted	\N	Iftikhar	2026-08-08 05:35:45.485175	\N	2026-08-08 05:35:45.485175	t	167	2026-08-08 06:25:49.267
93	2026-08-07	25	9	14	Night	submitted	\N	Iftikhar	2026-08-08 05:41:02.110074	\N	2026-08-08 05:41:02.110074	t	167	2026-08-08 06:25:49.267
94	2026-08-07	14	9	14	Night	submitted	\N	Iftikhar	2026-08-08 05:42:10.302604	\N	2026-08-08 05:42:10.302604	t	167	2026-08-08 06:25:49.267
95	2026-08-07	15	2	14	Night	submitted	\N	Iftikhar	2026-08-08 05:43:24.316785	\N	2026-08-08 05:43:24.316785	t	167	2026-08-08 06:25:49.267
108	2026-08-08	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-09 07:52:30.892115	\N	2026-08-09 07:52:30.892115	t	186	2026-08-10 09:23:21.156
109	2026-08-08	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-09 07:53:28.839697	\N	2026-08-09 07:53:28.839697	t	186	2026-08-10 09:23:21.156
113	2026-08-08	22	2	13	Night	submitted	\N	Iftikhar	2026-08-09 07:59:33.485241	\N	2026-08-09 07:59:33.485241	t	186	2026-08-10 09:23:21.156
115	2026-08-08	24	9	13	Night	submitted	\N	Iftikhar	2026-08-09 08:03:42.711767	\N	2026-08-09 08:03:42.711767	t	186	2026-08-10 09:23:21.156
114	2026-08-08	23	2	13	Night	submitted	\N	Iftikhar	2026-08-09 08:02:40.567269	Iftikhar	2026-08-09 08:05:59.595	t	186	2026-08-10 09:23:21.156
116	2026-08-09	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-10 05:23:01.976288	\N	2026-08-10 05:23:01.976288	t	187	2026-08-10 09:25:50.817
117	2026-08-09	14	1	14	Morning	submitted	\N	Iftikhar	2026-08-10 05:24:06.205199	\N	2026-08-10 05:24:06.205199	t	187	2026-08-10 09:25:50.817
118	2026-08-09	15	7	14	Morning	submitted	\N	Iftikhar	2026-08-10 05:25:09.40753	\N	2026-08-10 05:25:09.40753	t	187	2026-08-10 09:25:50.817
122	2026-08-09	14	9	14	Night	submitted	\N	Iftikhar	2026-08-10 05:28:46.604898	\N	2026-08-10 05:28:46.604898	t	187	2026-08-10 09:25:50.817
123	2026-08-09	15	9	14	Night	submitted	\N	Iftikhar	2026-08-10 05:30:46.537843	\N	2026-08-10 05:30:46.537843	t	187	2026-08-10 09:25:50.817
105	2026-08-08	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-09 07:48:31.9882	\N	2026-08-09 07:48:31.9882	t	188	2026-08-10 09:27:37.036
106	2026-08-08	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-09 07:50:05.863588	\N	2026-08-09 07:50:05.863588	t	188	2026-08-10 09:27:37.036
107	2026-08-08	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-09 07:51:04.678261	\N	2026-08-09 07:51:04.678261	t	188	2026-08-10 09:27:37.036
111	2026-08-08	14	9	14	Night	submitted	\N	Iftikhar	2026-08-09 07:56:12.533537	\N	2026-08-09 07:56:12.533537	t	188	2026-08-10 09:27:37.036
112	2026-08-08	15	2	14	Night	submitted	\N	Iftikhar	2026-08-09 07:58:42.067577	\N	2026-08-09 07:58:42.067577	t	188	2026-08-10 09:27:37.036
110	2026-08-08	25	9	14	Night	submitted	\N	Iftikhar	2026-08-09 07:54:53.092125	Iftikhar	2026-08-09 08:41:15.456	t	188	2026-08-10 09:27:37.036
119	2026-08-09	22	7	13	Morning	submitted	\N	Iftikhar	2026-08-10 05:26:09.923348	\N	2026-08-10 05:26:09.923348	t	189	2026-08-10 10:26:19.752
120	2026-08-09	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-10 05:27:03.589931	\N	2026-08-10 05:27:03.589931	t	189	2026-08-10 10:26:19.752
121	2026-08-09	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-10 05:28:03.324527	\N	2026-08-10 05:28:03.324527	t	189	2026-08-10 10:26:19.752
125	2026-08-09	24	9	13	Night	submitted	\N	Iftikhar	2026-08-10 05:33:23.641765	\N	2026-08-10 05:33:23.641765	t	189	2026-08-10 10:26:19.752
124	2026-08-09	22	9	13	Night	submitted	\N	Iftikhar	2026-08-10 05:32:19.376356	Iftikhar	2026-08-10 05:34:55.987	t	189	2026-08-10 10:26:19.752
199	2026-08-18	21	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-19 04:21:41.522123	\N	2026-08-19 04:21:41.522123	t	231	2026-08-19 07:22:53.019
203	2026-08-18	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-19 04:25:30.946876	\N	2026-08-19 04:25:30.946876	t	231	2026-08-19 07:22:53.019
197	2026-08-18	15	8	17	Morning	submitted	\N	Iftikhar Ahmed	2026-08-19 04:19:54.187297	\N	2026-08-19 04:19:54.187297	t	232	2026-08-19 07:25:15.902
136	2026-08-11	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-12 05:16:36.540058	\N	2026-08-12 05:16:36.540058	t	203	2026-08-12 09:41:16.297
137	2026-08-11	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-12 05:19:50.744193	\N	2026-08-12 05:19:50.744193	t	203	2026-08-12 09:41:16.297
143	2026-08-11	14	9	14	Night	submitted	\N	Iftikhar	2026-08-12 05:25:55.225812	\N	2026-08-12 05:25:55.225812	t	203	2026-08-12 09:41:16.297
144	2026-08-11	15	2	14	Night	submitted	\N	Iftikhar	2026-08-12 05:28:07.246176	\N	2026-08-12 05:28:07.246176	t	203	2026-08-12 09:41:16.297
142	2026-08-11	25	9	14	Night	submitted	\N	Iftikhar	2026-08-12 05:24:37.373175	Iftikhar	2026-08-12 07:30:10.021	t	203	2026-08-12 09:41:16.297
147	2026-08-11	21	9	16	Night	submitted	\N	Iftikhar	2026-08-12 05:30:31.757677	\N	2026-08-12 05:30:31.757677	t	204	2026-08-12 09:58:09.956
148	2026-08-12	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-13 04:43:22.223796	\N	2026-08-13 04:43:22.223796	t	208	2026-08-13 08:11:22.65
149	2026-08-12	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-13 04:44:35.224753	\N	2026-08-13 04:44:35.224753	t	208	2026-08-13 08:11:22.65
150	2026-08-12	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-13 04:45:34.228718	\N	2026-08-13 04:45:34.228718	t	208	2026-08-13 08:11:22.65
153	2026-08-12	25	9	14	Night	submitted	\N	Iftikhar	2026-08-13 04:48:05.77479	\N	2026-08-13 04:48:05.77479	t	208	2026-08-13 08:11:22.65
154	2026-08-12	14	9	14	Night	submitted	\N	Iftikhar	2026-08-13 04:49:14.216822	\N	2026-08-13 04:49:14.216822	t	208	2026-08-13 08:11:22.65
155	2026-08-12	15	2	14	Night	submitted	\N	Iftikhar	2026-08-13 04:50:17.260845	\N	2026-08-13 04:50:17.260845	t	208	2026-08-13 08:11:22.65
151	2026-08-12	18	7	16	Morning	submitted	\N	Iftikhar	2026-08-13 04:46:21.136222	\N	2026-08-13 04:46:21.136222	t	210	2026-08-15 10:32:09.085
156	2026-08-12	19	2	16	Night	submitted	\N	Iftikhar	2026-08-13 04:51:23.964216	\N	2026-08-13 04:51:23.964216	t	211	2026-08-15 10:46:23.243
152	2026-08-12	19	7	16	Morning	submitted	\N	Iftikhar	2026-08-13 04:46:55.696827	Iftikhar Ahmed	2026-08-15 05:54:52.428	t	211	2026-08-15 10:46:23.243
157	2026-08-13	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-15 05:57:47.128772	\N	2026-08-15 05:57:47.128772	t	212	2026-08-15 10:54:39.533
158	2026-08-13	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-15 06:02:43.362655	\N	2026-08-15 06:02:43.362655	t	212	2026-08-15 10:54:39.533
160	2026-08-13	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-15 06:04:23.470122	\N	2026-08-15 06:04:23.470122	t	212	2026-08-15 10:54:39.533
162	2026-08-13	20	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-15 06:07:04.277791	\N	2026-08-15 06:07:04.277791	t	212	2026-08-15 10:54:39.533
163	2026-08-13	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-15 06:08:05.670254	\N	2026-08-15 06:08:05.670254	t	212	2026-08-15 10:54:39.533
164	2026-08-13	14	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-15 06:08:57.221169	\N	2026-08-15 06:08:57.221169	t	212	2026-08-15 10:54:39.533
166	2026-08-13	18	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-15 06:11:02.348358	\N	2026-08-15 06:11:02.348358	t	212	2026-08-15 10:54:39.533
161	2026-08-13	19	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-15 06:06:26.1927	\N	2026-08-15 06:06:26.1927	t	213	2026-08-15 10:55:28.633
167	2026-08-13	19	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-15 06:12:14.852552	\N	2026-08-15 06:12:14.852552	t	213	2026-08-15 10:55:28.633
159	2026-08-13	15	8	14	Morning	submitted	\N	Iftikhar Ahmed	2026-08-15 06:03:48.665526	\N	2026-08-15 06:03:48.665526	t	214	2026-08-15 10:56:48.246
165	2026-08-13	15	2	14	Night	submitted	\N	Iftikhar Ahmed	2026-08-15 06:09:52.093661	\N	2026-08-15 06:09:52.093661	t	214	2026-08-15 10:56:48.246
168	2026-08-15	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-16 07:15:31.554374	\N	2026-08-16 07:15:31.554374	t	226	2026-08-17 13:05:21.35
169	2026-08-15	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-16 07:16:46.800647	\N	2026-08-16 07:16:46.800647	t	226	2026-08-17 13:05:21.35
170	2026-08-15	15	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-16 07:17:47.960176	\N	2026-08-16 07:17:47.960176	t	226	2026-08-17 13:05:21.35
171	2026-08-15	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-16 07:18:54.385539	\N	2026-08-16 07:18:54.385539	t	226	2026-08-17 13:05:21.35
172	2026-08-15	19	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-16 07:19:35.018273	\N	2026-08-16 07:19:35.018273	t	226	2026-08-17 13:05:21.35
174	2026-08-15	14	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-16 07:23:35.942302	\N	2026-08-16 07:23:35.942302	t	226	2026-08-17 13:05:21.35
175	2026-08-15	15	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-16 07:24:50.375929	\N	2026-08-16 07:24:50.375929	t	226	2026-08-17 13:05:21.35
176	2026-08-15	18	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-16 07:25:54.684036	\N	2026-08-16 07:25:54.684036	t	226	2026-08-17 13:05:21.35
177	2026-08-15	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-16 07:27:02.334141	\N	2026-08-16 07:27:02.334141	t	226	2026-08-17 13:05:21.35
173	2026-08-15	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-16 07:20:49.866285	Tahir Hassan	2026-08-17 12:59:49.125	t	226	2026-08-17 13:05:21.35
178	2026-08-16	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-17 05:21:35.499855	\N	2026-08-17 05:21:35.499855	t	227	2026-08-17 13:06:45.171
179	2026-08-16	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-17 05:22:36.693698	\N	2026-08-17 05:22:36.693698	t	227	2026-08-17 13:06:45.171
180	2026-08-16	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-17 05:23:30.453518	\N	2026-08-17 05:23:30.453518	t	227	2026-08-17 13:06:45.171
181	2026-08-16	21	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-17 05:24:23.26763	\N	2026-08-17 05:24:23.26763	t	227	2026-08-17 13:06:45.171
182	2026-08-16	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-17 05:25:28.201228	\N	2026-08-17 05:25:28.201228	t	227	2026-08-17 13:06:45.171
183	2026-08-16	14	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-17 05:26:31.576617	\N	2026-08-17 05:26:31.576617	t	227	2026-08-17 13:06:45.171
184	2026-08-16	18	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-17 05:27:33.906173	\N	2026-08-17 05:27:33.906173	t	227	2026-08-17 13:06:45.171
185	2026-08-16	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-17 05:28:25.149654	\N	2026-08-17 05:28:25.149654	t	227	2026-08-17 13:06:45.171
186	2026-08-17	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-18 04:52:31.321758	\N	2026-08-18 04:52:31.321758	t	228	2026-08-19 07:06:41.512
187	2026-08-17	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-18 04:53:36.119909	\N	2026-08-18 04:53:36.119909	t	228	2026-08-19 07:06:41.512
188	2026-08-17	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-18 04:54:41.341051	\N	2026-08-18 04:54:41.341051	t	228	2026-08-19 07:06:41.512
190	2026-08-17	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-18 04:56:56.733562	\N	2026-08-18 04:56:56.733562	t	228	2026-08-19 07:06:41.512
189	2026-08-17	21	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-18 04:55:37.622849	\N	2026-08-18 04:55:37.622849	t	229	2026-08-19 07:14:29.648
193	2026-08-17	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-18 05:00:05.173048	\N	2026-08-18 05:00:05.173048	t	229	2026-08-19 07:14:29.648
194	2026-08-18	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-19 04:14:15.119295	\N	2026-08-19 04:14:15.119295	t	230	2026-08-19 07:21:34.191
195	2026-08-18	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-19 04:18:39.081607	\N	2026-08-19 04:18:39.081607	t	230	2026-08-19 07:21:34.191
196	2026-08-18	15	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-19 04:19:23.905054	\N	2026-08-19 04:19:23.905054	t	230	2026-08-19 07:21:34.191
198	2026-08-18	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-19 04:20:43.446799	\N	2026-08-19 04:20:43.446799	t	230	2026-08-19 07:21:34.191
200	2026-08-18	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-19 04:22:41.562026	\N	2026-08-19 04:22:41.562026	t	230	2026-08-19 07:21:34.191
191	2026-08-17	14	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-18 04:58:03.260133	\N	2026-08-18 04:58:03.260133	t	228	2026-08-19 07:06:41.512
192	2026-08-17	18	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-18 04:59:14.986452	\N	2026-08-18 04:59:14.986452	t	228	2026-08-19 07:06:41.512
201	2026-08-18	14	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-19 04:23:38.595844	\N	2026-08-19 04:23:38.595844	t	230	2026-08-19 07:21:34.191
202	2026-08-18	18	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-19 04:24:34.972893	\N	2026-08-19 04:24:34.972893	t	230	2026-08-19 07:21:34.191
\.


--
-- Data for Name: department_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.department_master (id, name, code) FROM stdin;
1	Administration	0001
3	Loader	0003
4	Checker	0004
2	Operator	0002
\.


--
-- Data for Name: employee_advances; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_advances (id, employee_id, date, amount, notes, created_at) FROM stdin;
1	15	2026-08-06	10000	For rashan k liye	2026-08-06 13:47:29.301977
5	14	2026-08-10	5000	Advance 	2026-08-10 13:37:08.800964
6	16	2026-08-12	5000	\N	2026-08-12 10:43:39.53903
7	14	2026-08-13	2000	\N	2026-08-13 12:56:40.4883
8	11	2026-08-15	10000	family wedding	2026-08-15 13:39:16.459103
9	16	2026-08-15	5000	\N	2026-08-15 13:41:19.554272
10	14	2026-08-15	5000	\N	2026-08-15 13:41:28.057675
11	9	2026-08-17	5000	\N	2026-08-17 13:18:15.574669
12	10	2026-08-18	1000	\N	2026-08-19 07:41:34.62213
\.


--
-- Data for Name: employee_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_master (id, name, code, department_id, base_salary, overtime_rate_hr, att_allowance, oth_allowance, active) FROM stdin;
10	Iftikhar	9901	1	55000.00	\N	\N	\N	t
11	Imran	9902	1	36000.00	\N	\N	\N	t
12	Liaquat	9903	1	80000.00	\N	\N	\N	t
1	Umaid	001	2	1200.00	\N	2000.00	2000.00	t
2	Nasir	002	2	1200.00	\N	2000.00	2000.00	t
4	Rasheed	003	2	1200.00	\N	2000.00	2000.00	f
3	Sajiid Rehman	004	2	1200.00	\N	2000.00	2000.00	t
5	Zain	005	2	1200.00	\N	2000.00	2000.00	f
6	Rashid	006	2	1200.00	\N	2000.00	2000.00	f
7	Raza	007	2	1200.00	\N	2000.00	2000.00	t
8	Gul Muhammad	008	2	1200.00	\N	2000.00	2000.00	t
9	Kareem	009	2	1200.00	\N	2000.00	2000.00	t
14	Safdar	9905	3	30000.00	100.00	3000.00	\N	t
16	Sardar	9907	3	30000.00	100.00	3000.00	\N	t
15	Dilshad	9906	3	30000.00	100.00	3000.00	\N	t
13	Zulfiqar	9904	4	33000.00	\N	2000.00	\N	f
17	Shiraj	9908	4	33000.00	\N	2000.00	\N	t
18	Quality 	011	2	\N	\N	\N	\N	t
19	Muhammad Moosa	9909	4	33000.00	110.00	2000.00	\N	t
\.


--
-- Data for Name: employee_salary_records; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_salary_records (id, employee_id, date, base_wage, commission, final_salary, created_at) FROM stdin;
\.


--
-- Data for Name: employee_salary_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_salary_settings (id, employee_id, base_daily_wage) FROM stdin;
1	2	1200
2	4	1200.00
3	6	1200.00
4	3	1200.00
5	1	1200.00
6	5	1200.00
\.


--
-- Data for Name: fabric_type_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fabric_type_master (id, name, code) FROM stdin;
4	RIB (1X1)	RIB (1X1)
2	2-Fleece	2-Fleece
13	3-Fleece	3-Fleece
14	Single Jersey Double Tar	Single Jersey Double Tar
15	RIB (1X1) Double Tar	RIB (1X1) Double Tar
3	RIB (2X1) Double Tar	RIB (2X1) Double Tar
1	Single Jersey	Single Jersey
16	RIB (2X1)	RIB (2X1)
\.


--
-- Data for Name: factory_maintenance; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.factory_maintenance (id, maintenance_date, category, maintenance_work, status, created_by, created_at, updated_by, updated_at) FROM stdin;
\.


--
-- Data for Name: invoice; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoice (id, invoice_date, company_id, party_id, status, fbr_invoice_number, fbr_status_code, fbr_raw_response, total_value, total_tax, grand_total, created_by, created_at, updated_at, posted_at, due_days, origin) FROM stdin;
217	2026-02-28	1	15	posted	217	\N	\N	2881.50	518.67	3400.17	tahirhassan	2026-08-16 18:18:29.549641	2026-08-16 18:18:29.549641	2026-02-28 00:00:00	90	manual
224	2026-03-31	1	20	posted	224	\N	\N	17115.00	3080.70	20195.70	tahirhassan	2026-08-16 18:23:32.689355	2026-08-16 18:23:32.689355	2026-03-31 00:00:00	60	manual
226	2026-04-30	1	13	posted	226	\N	\N	428735.75	77172.44	505908.19	tahirhassan	2026-08-16 18:28:04.756605	2026-08-16 18:28:04.756605	2026-04-30 00:00:00	90	manual
227	2026-04-30	1	19	posted	227	\N	\N	156160.65	28108.92	184269.57	tahirhassan	2026-08-16 18:31:12.152217	2026-08-16 18:31:12.152217	2026-04-30 00:00:00	90	manual
229	2026-04-30	1	14	posted	229	\N	\N	494865.60	89075.80	583941.40	tahirhassan	2026-08-16 18:37:07.979136	2026-08-16 18:37:07.979136	2026-04-30 00:00:00	60	manual
243	2026-06-30	1	14	posted	243	\N	\N	404990.10	72898.22	477888.32	tahirhassan	2026-08-16 18:40:59.347969	2026-08-16 18:40:59.347969	2026-06-30 00:00:00	60	manual
231	2026-04-30	1	20	posted	231	\N	\N	59255.00	10665.90	69920.90	tahirhassan	2026-08-16 18:45:05.722669	2026-08-16 18:45:05.722669	2026-04-30 00:00:00	60	manual
233	2026-04-30	1	15	posted	233	\N	\N	123429.25	22217.27	145646.52	tahirhassan	2026-08-16 18:46:51.953058	2026-08-16 18:46:51.953058	2026-04-30 00:00:00	90	manual
241	2026-05-31	1	15	posted	241	\N	\N	226504.25	40770.77	267275.02	tahirhassan	2026-08-16 18:47:40.907112	2026-08-16 18:47:40.907112	2026-05-31 00:00:00	90	manual
251	2026-07-31	1	15	posted	251	\N	\N	122958.50	22132.53	145091.03	tahirhassan	2026-08-16 18:48:22.077033	2026-08-16 18:48:22.077033	2026-07-31 00:00:00	90	manual
234	2026-05-31	1	13	posted	234	\N	\N	323617.60	58251.17	381868.77	tahirhassan	2026-08-16 18:50:17.268544	2026-08-16 18:50:17.268544	2026-05-31 00:00:00	90	manual
242	2026-06-30	1	13	posted	242	\N	\N	378025.60	68044.61	446070.21	tahirhassan	2026-08-16 18:51:00.488544	2026-08-16 18:51:00.488544	2026-06-30 00:00:00	90	manual
247	2026-07-31	1	13	posted	247	\N	\N	478567.00	86142.06	564709.06	tahirhassan	2026-08-16 18:52:29.550241	2026-08-16 18:52:29.550241	2026-07-31 00:00:00	90	manual
236	2026-05-31	1	16	posted	236	\N	\N	119130.10	21443.42	140573.52	tahirhassan	2026-08-16 18:58:39.777194	2026-08-16 18:58:39.777194	2026-05-31 00:00:00	90	manual
253	2026-07-31	1	16	posted	253	\N	\N	541957.10	97552.28	639509.38	tahirhassan	2026-08-16 19:00:45.962379	2026-08-16 19:00:45.962379	2026-07-31 00:00:00	90	manual
254	2026-07-31	1	17	posted	254	\N	\N	10409.80	1873.76	12283.56	tahirhassan	2026-08-16 19:02:48.116447	2026-08-16 19:02:48.116447	2026-07-31 00:00:00	60	manual
239	2026-05-31	1	20	posted	239	\N	\N	58040.00	10447.20	68487.20	tahirhassan	2026-08-16 19:06:41.432595	2026-08-16 19:06:41.432595	2026-05-31 00:00:00	60	manual
245	2026-06-30	1	20	posted	245	\N	\N	4316.00	776.88	5092.88	tahirhassan	2026-08-16 19:07:47.507629	2026-08-16 19:07:47.507629	2026-06-30 00:00:00	60	manual
250	2026-07-31	1	20	posted	250	\N	\N	9444.00	1699.92	11143.92	tahirhassan	2026-08-16 19:08:37.313106	2026-08-16 19:08:37.313106	2026-07-31 00:00:00	60	manual
244	2026-06-30	1	18	posted	244	\N	\N	689071.04	124032.79	813103.83	tahirhassan	2026-08-16 19:14:37.712952	2026-08-16 19:14:37.712952	2026-06-30 00:00:00	60	manual
249	2026-07-31	1	18	posted	249	\N	\N	25388.00	4569.84	29957.84	tahirhassan	2026-08-16 19:15:26.539317	2026-08-16 19:15:26.539317	2026-07-31 00:00:00	60	manual
200	2025-11-30	1	15	posted	200	\N	\N	532900.05	95922.01	628822.06	tahirhassan	2026-08-16 19:23:21.659572	2026-08-16 19:23:21.659572	2025-11-30 00:00:00	90	manual
235	2026-05-31	1	19	posted	235	\N	\N	667.00	120.06	787.06	tahirhassan	2026-08-16 19:27:26.921896	2026-08-16 19:27:26.921896	2026-05-31 00:00:00	90	manual
252	2026-07-31	1	19	posted	252	\N	\N	81442.80	14659.70	96102.50	tahirhassan	2026-08-16 19:29:45.765231	2026-08-16 19:29:45.765231	2026-07-31 00:00:00	90	manual
237	2026-05-31	1	14	posted	237	\N	\N	912040.90	164167.36	1076208.26	tahirhassan	2026-08-16 20:00:45.71659	2026-08-16 20:00:45.71659	2026-05-31 00:00:00	60	manual
248	2026-07-31	1	14	posted	248	\N	\N	393172.90	70771.13	463944.03	tahirhassan	2026-08-16 20:18:07.936155	2026-08-16 20:18:07.936155	2026-07-31 00:00:00	60	manual
\.


--
-- Data for Name: invoice_item; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoice_item (id, invoice_id, yarn_type_id, yarn_count_id, hs_code, uom, product_description, quantity, rate_per_kg, value_excluding_tax, tax_amount, total_value, sale_type) FROM stdin;
1	217	20	45	\N	\N	\N	31.650	50.00	1582.50	284.85	1867.35	Goods at standard rate (default)
2	217	22	15	\N	\N	\N	22.750	50.00	1137.50	204.75	1342.25	Goods at standard rate (default)
3	217	24	39	\N	\N	\N	1.700	95.00	161.50	29.07	190.57	Goods at standard rate (default)
4	224	20	31	\N	\N	\N	142.750	100.00	14275.00	2569.50	16844.50	Goods at standard rate (default)
5	224	24	16	\N	\N	\N	6.000	100.00	600.00	108.00	708.00	Goods at standard rate (default)
6	224	24	13	\N	\N	\N	4.000	100.00	400.00	72.00	472.00	Goods at standard rate (default)
7	224	24	13	\N	\N	\N	18.400	100.00	1840.00	331.20	2171.20	Goods at standard rate (default)
8	226	22	13	\N	\N	\N	12434.000	22.00	273548.00	49238.64	322786.64	Goods at standard rate (default)
9	226	22	2	\N	\N	\N	1607.500	24.00	38580.00	6944.40	45524.40	Goods at standard rate (default)
10	226	20	27	\N	\N	\N	3331.650	35.00	116607.75	20989.40	137597.15	Goods at standard rate (default)
11	227	20	47	\N	\N	\N	5384.850	29.00	156160.65	28108.92	184269.57	Goods at standard rate (default)
12	229	20	49	\N	\N	\N	12071.400	32.00	386284.80	69531.26	455816.06	Goods at standard rate (default)
13	229	20	28	\N	\N	\N	3393.150	32.00	108580.80	19544.54	128125.34	Goods at standard rate (default)
16	243	20	28	\N	\N	\N	5231.400	32.00	167404.80	30132.86	197537.66	Goods at standard rate (default)
17	243	20	29	\N	\N	\N	4415.050	34.00	150111.70	27020.11	177131.81	Goods at standard rate (default)
18	243	23	36	\N	\N	\N	2733.550	32.00	87473.60	15745.25	103218.85	Goods at standard rate (default)
21	231	20	23	\N	\N	\N	520.250	100.00	52025.00	9364.50	61389.50	Goods at standard rate (default)
22	231	24	2	\N	\N	\N	85.950	50.00	4297.50	773.55	5071.05	Goods at standard rate (default)
23	231	22	2	\N	\N	\N	58.650	50.00	2932.50	527.85	3460.35	Goods at standard rate (default)
24	233	20	23	\N	\N	\N	3526.550	35.00	123429.25	22217.27	145646.52	Goods at standard rate (default)
25	241	20	23	\N	\N	\N	6471.550	35.00	226504.25	40770.77	267275.02	Goods at standard rate (default)
26	251	20	23	\N	\N	\N	3513.100	35.00	122958.50	22132.53	145091.03	Goods at standard rate (default)
27	234	20	23	\N	\N	\N	10113.050	32.00	323617.60	58251.17	381868.77	Goods at standard rate (default)
28	242	20	23	\N	\N	\N	11813.300	32.00	378025.60	68044.61	446070.21	Goods at standard rate (default)
29	247	20	23	\N	\N	\N	14844.900	32.00	475036.80	85506.62	560543.42	Goods at standard rate (default)
30	247	20	26	\N	\N	\N	49.400	35.00	1729.00	311.22	2040.22	Goods at standard rate (default)
31	247	20	27	\N	\N	\N	47.400	38.00	1801.20	324.22	2125.42	Goods at standard rate (default)
32	236	20	23	\N	\N	\N	3162.650	34.00	107530.10	19355.42	126885.52	Goods at standard rate (default)
33	236	23	39	\N	\N	\N	145.000	80.00	11600.00	2088.00	13688.00	Goods at standard rate (default)
34	253	20	26	\N	\N	\N	11828.750	34.00	402177.50	72391.95	474569.45	Goods at standard rate (default)
35	253	24	39	\N	\N	\N	1688.100	80.00	135048.00	24308.64	159356.64	Goods at standard rate (default)
36	253	22	13	\N	\N	\N	197.150	24.00	4731.60	851.69	5583.29	Goods at standard rate (default)
37	254	20	46	\N	\N	\N	335.800	31.00	10409.80	1873.76	12283.56	Goods at standard rate (default)
38	239	20	29	\N	\N	\N	200.000	80.00	16000.00	2880.00	18880.00	Goods at standard rate (default)
39	239	20	29	\N	\N	\N	65.550	80.00	5244.00	943.92	6187.92	Goods at standard rate (default)
40	239	20	29	\N	\N	\N	134.950	90.00	12145.50	2186.19	14331.69	Goods at standard rate (default)
41	239	24	2	\N	\N	\N	135.050	80.00	10804.00	1944.72	12748.72	Goods at standard rate (default)
42	239	23	40	\N	\N	\N	106.050	90.00	9544.50	1718.01	11262.51	Goods at standard rate (default)
43	239	22	2	\N	\N	\N	47.800	90.00	4302.00	774.36	5076.36	Goods at standard rate (default)
44	245	20	29	\N	\N	\N	52.100	80.00	4168.00	750.24	4918.24	Goods at standard rate (default)
45	245	23	2	\N	\N	\N	1.850	80.00	148.00	26.64	174.64	Goods at standard rate (default)
46	250	20	29	\N	\N	\N	118.050	80.00	9444.00	1699.92	11143.92	Goods at standard rate (default)
47	244	22	17	\N	\N	\N	8203.270	27.00	221488.29	39867.89	261356.18	Goods at standard rate (default)
48	244	20	29	\N	\N	\N	11654.000	40.00	466160.00	83908.80	550068.80	Goods at standard rate (default)
49	244	23	2	\N	\N	\N	40.650	35.00	1422.75	256.10	1678.85	Goods at standard rate (default)
50	249	20	29	\N	\N	\N	634.700	40.00	25388.00	4569.84	29957.84	Goods at standard rate (default)
51	200	20	28	\N	\N	\N	12936.100	35.00	452763.50	81497.43	534260.93	Goods at standard rate (default)
52	200	22	2	\N	\N	\N	144.300	26.00	3751.80	675.32	4427.12	Goods at standard rate (default)
53	200	23	38	\N	\N	\N	804.050	95.00	76384.75	13749.26	90134.01	Goods at standard rate (default)
54	235	20	47	\N	\N	\N	23.000	29.00	667.00	120.06	787.06	Goods at standard rate (default)
55	252	24	37	\N	\N	\N	3016.400	27.00	81442.80	14659.70	96102.50	Goods at standard rate (default)
56	237	20	28	\N	\N	\N	17676.050	32.00	565633.60	101814.05	667447.65	Goods at standard rate (default)
57	237	20	29	\N	\N	\N	9297.250	34.00	316106.50	56899.17	373005.67	Goods at standard rate (default)
58	237	23	36	\N	\N	\N	946.900	32.00	30300.80	5454.14	35754.94	Goods at standard rate (default)
59	248	20	29	\N	\N	\N	6520.050	34.00	221681.70	39902.71	261584.41	Goods at standard rate (default)
60	248	20	28	\N	\N	\N	5359.100	32.00	171491.20	30868.42	202359.62	Goods at standard rate (default)
\.


--
-- Data for Name: invoice_payment; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoice_payment (id, invoice_id, amount, tax_deduction, payment_date, method, reference, notes, paid_by, created_at) FROM stdin;
1	200	70241.00	0.00	2026-05-22	Cheque	CA-86523688	Soneri Bank	tahirhassan	2026-08-16 19:48:42.403862
\.


--
-- Data for Name: invoice_transaction; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoice_transaction (id, invoice_id, transaction_header_id) FROM stdin;
\.


--
-- Data for Name: job_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.job_master (id, name, code, party_id) FROM stdin;
19	Feroze	Feroze	18
16	GWCC	GWCC	15
15	Lucky Knits	Lucky Knits	14
17	Mahad	Mahad	17
14	Perfect	Perfact	16
13	Towellers	Towellers	13
18	Eastern Garments	Eastern	19
\.


--
-- Data for Name: location_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.location_master (id, name, code) FROM stdin;
13	New Karachi	L-001
14	SITE Area	L-002
15	SITE-II Scheme 33	L-003
16	Landhi Industrial Area	L-004
17	Hub Chowki	L-005
18	Kathor, Super Highway	L-006
\.


--
-- Data for Name: machine_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.machine_history (id, machine_id, machine_number, name, making_rate, needle_change_date, needle_brand, sinker_change_date, sinker_brand, action, changed_by, changed_at) FROM stdin;
1	14	M-002	M#02	3.75	2026-04-10	Sigma	2026-04-10	Kohala	created	system	2026-08-19 20:36:16.964424
2	15	M-003	M#03	3.75	2026-07-29	Sigma	2026-07-29	Kohala	created	system	2026-08-19 20:36:16.964424
3	18	M-004	M#04	3.75	2025-11-26	Sigma	2025-11-26	Kohala	created	system	2026-08-19 20:36:16.964424
4	19	M-005	M#05	3.00	2026-01-15	Sigma	2026-01-21	Kohala	created	system	2026-08-19 20:36:16.964424
5	20	M-006	M#06	3.00	2026-01-13	Sigma	2026-01-13	Sigma/YGH	created	system	2026-08-19 20:36:16.964424
6	21	M-007	M#07	4.00	2026-07-16	Sigma	2026-07-16	Sigma	created	system	2026-08-19 20:36:16.964424
7	22	M-008	M#08	3.75	2026-04-25	Sigma	2026-04-25	Kohala	created	system	2026-08-19 20:36:16.964424
8	23	M-009	M#09	3.75	2026-01-26	Sigma	2026-06-12	Kohala	created	system	2026-08-19 20:36:16.964424
9	24	M-010	M#10	3.75	2026-07-31	KE Needle	2026-07-31	Kohala	created	system	2026-08-19 20:36:16.964424
10	25	M-001	M#01	3.75	2025-12-24	Sigma	2025-12-24	Kohala	created	system	2026-08-19 20:36:16.964424
\.


--
-- Data for Name: machine_maintenance; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.machine_maintenance (id, maintenance_date, machine_id, maintenance_work, cost, vendor, status, created_by, created_at, updated_by, updated_at) FROM stdin;
1	2026-08-10	20	Machine No. 6 — Work Date Sheet\n\nکام شروع ہونے کی تاریخ: 11-08-2026\nکام مکمل ہونے کا دورانیہ: 5 دن\n\nکروائے گئے کام\n\n1. S/Jersey کو Cross 3 Fleece میں Convert کیا گیا۔\n2. Mechanic کو بلا کر 6 تانگوں میں گٹکے بنوائے گئے۔\n3. ڈائل کے اندر 5 نمبر Elki کے Hall کروائے گئے۔\n4. Machine No. 3 کی سوئی اور شنکر Machine No. 6 میں ڈالے گئے۔\n5. مشین کا کام مکمل ہونے میں 5 دن لگے۔\n6. کپڑا نیچے آنے کے بعد ایک رول بنا کر چیک کیا گیا۔\n7. چیکنگ کے دوران کپڑے میں سفید لائنیں (White Lines) نظر آئیں۔\n8. سفید لائنیں آنے کے بعد Machine No. 6 بند کر دی گئی۔\n\nFinal Status\n\nMachine No. 6: بند — کپڑے میں سفید لائنوں کا مسئلہ چیک کرنا باقی ہے۔	6000.000	Amjad	cancelled	Iftikhar Ahmed	2026-08-15 15:47:43.250295	Iftikhar Ahmed	2026-08-15 16:01:52.143
2	2026-08-10	20	مشین نمبر 6 — سنگل جرسی سے تھری فلیس میں تبدیلی\n\n1. مشین نمبر 6 کو سنگل جرسی سے تھری فلیس میں تبدیل کیا گیا۔\n\n2. مکینک نے 6 گٹکے تیار کروائے، جو 6 ٹانگوں کے لیے تھے۔\n\n3. ڈائل میں سوراخ کروائے گئے۔\n\n4. مشین نمبر 3 کی سوئیاں اور شنکر مشین نمبر 6 میں لگا دیے گئے۔\n\n5. مشین نمبر 6 کو اسٹارٹ کیا گیا اور ایک رول تیار کیا گیا۔\n\n6. تیار کیے گئے رول کی چیکنگ کے دوران کپڑے میں شیڈ لائن نظر آئی۔\n\n7. شیڈ لائن کی وجہ سے مشین نمبر 6 کو بند کر دیا گیا تاکہ خرابی کو چیک کرکے درست کیا جا سکے۔	6000.000	Amjad	submitted	Iftikhar Ahmed	2026-08-15 16:10:23.450009	\N	2026-08-15 16:10:23.450009
3	2026-08-15	21	مشین نمبر 7 — تبدیلی اور پروڈکشن رپورٹ\n\nتاریخ: 15-08-2026\n\n1. مشین نمبر 7 پہلے 1×1 لائکرا رِب تیار کر رہی تھی۔\n\n2. مشین نمبر 7 کو 1×1 لائکرا رِب سے 2×1 لائکرا رِب میں تبدیل کر دیا گیا۔\n\n3. اس تبدیلی کے لیے پرانے والی سوئیوں کا استعمال کیا گیا۔\n\n4. تبدیلی کا کام مکمل ہونے کے بعد پرفیکٹ کمپنی کی پروڈکشن شروع کر دی گئی۔	\N	Master	submitted	Iftikhar Ahmed	2026-08-15 16:16:43.897275	\N	2026-08-15 16:16:43.897275
4	2026-08-08	23	Machine No. 9 — Work Report\n\nDate: 08/08/2026\n\n1. MPF change کروایا گیا۔\n2. تین Bald change کروائے گئے۔\n3. MPF wire change کروایا گیا۔	\N	\N	submitted	Iftikhar Ahmed	2026-08-18 05:37:51.831295	\N	2026-08-18 05:37:51.831295
\.


--
-- Data for Name: machine_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.machine_master (id, name, machine_number, making_rate, needle_change_date, needle_brand, sinker_change_date, sinker_brand) FROM stdin;
14	M#02	M-002	3.75	2026-04-10	Sigma	2026-04-10	Kohala
15	M#03	M-003	3.75	2026-07-29	Sigma	2026-07-29	Kohala
18	M#04	M-004	3.75	2025-11-26	Sigma	2025-11-26	Kohala
19	M#05	M-005	3.00	2026-01-15	Sigma	2026-01-21	Kohala
20	M#06	M-006	3.00	2026-01-13	Sigma	2026-01-13	Sigma/YGH
21	M#07	M-007	4.00	2026-07-16	Sigma	2026-07-16	Sigma
22	M#08	M-008	3.75	2026-04-25	Sigma	2026-04-25	Kohala
23	M#09	M-009	3.75	2026-01-26	Sigma	2026-06-12	Kohala
24	M#10	M-010	3.75	2026-07-31	KE Needle	2026-07-31	Kohala
25	M#01	M-001	3.75	2025-12-24	Sigma	2025-12-24	Kohala
\.


--
-- Data for Name: party_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.party_master (id, name, code, waste_percent, ntn_cnic, province, address, registration_type, credit_days) FROM stdin;
14	 Lucky Knits (Private) Limited	Lucky	1.00	2277359	Sindh	L-A-2/B, Block 21, FB Area, Karachi, Pakistan	Registered	60
21	Arif Silk	Arif	1.00	\N	\N	\N	Unregistered	90
19	Eastern Garments (Pvt) Limited	Eastern	1.00	0688665	Sindh	B-58, S.I.T.E, Karachi	Registered	90
18	Feroze 1888 Mills Limited	Feroze	2.00	0698565	Sindh	B-4/A, S.I.T.E, Karachi	Registered	60
15	GWCC	GWCC	1.00	1863333	Sindh	PLOT No 8/1-C, Street-5 Sector 12-C, North Karachi Industrial Area,  Karachi Central North Karachi Town	Registered	90
17	Mahad International	Mahad	1.00	A888524	Sindh	Plot No.H-160, Z-61, Floor No.2-3,, Super Highway SITE, Phase-2, Gadap Town, Karachi, Pakistan	Registered	60
20	PD-Feroze 1888 Mills Limited	Feroze PD	2.00	0698565	Sindh	B-4/A, S.I.T.E, Karachi	Registered	60
16	Perfect Apparel	Perfect	1.00	3754339	Sindh	Plot No.24/1, Sector 12-D, North Karachi Industrial Area, 	Registered	90
13	Towellers Limited	Towellers	1.00	0676889	Sindh	PLOT NO. W.S.A-30,, Block-1, Federal B Area,  Karachi Central, Gulberg Town, Karachi	Registered	90
\.


--
-- Data for Name: plausibility_baseline; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.plausibility_baseline (id, operation, field, median, iqr, mad, lower_bound, upper_bound, sample_count, computed_at) FROM stdin;
1	receipt	net_weight	1270.080000	1807.250000	1143.262512	0.000000	6691.830000	29	2026-08-19 11:33:54.672
2	receipt	quantity	23.000000	25.000000	17.791200	0.000000	98.000000	29	2026-08-19 11:33:54.698
3	receipt	wt_per_bag	45.360000	0.569091	0.843734	43.652727	47.067273	29	2026-08-19 11:33:54.71
4	receipt	net_total@receipt:party	2539.568000	2966.121750	2770.337434	0.000000	11437.933250	16	2026-08-19 11:33:54.723
5	receipt	net_total@receipt:count	1270.080000	3810.640000	1242.537408	0.000000	12702.000000	23	2026-08-19 11:33:54.75
6	receipt	net_total@receipt:party+count	1270.080000	3241.795000	1207.755612	0.000000	10995.465000	27	2026-08-19 11:33:54.786
7	receipt	net_total@receipt:party+brand	1265.040000	3482.060000	1217.674206	0.000000	11711.220000	24	2026-08-19 11:33:54.799
8	receipt	net_total@receipt:count+brand	1270.080000	3349.490000	1143.262512	0.000000	11318.550000	25	2026-08-19 11:33:54.808
9	receipt	net_total@receipt:date+party	2539.568000	2966.121750	2770.337434	0.000000	11437.933250	16	2026-08-19 11:33:54.819
10	receipt	net_total@receipt:date+party+count	1270.080000	3241.795000	1207.755612	0.000000	10995.465000	27	2026-08-19 11:33:54.831
26	delivery	net_total@delivery:type	706.825000	2814.487500	1027.849515	0.000000	9150.287500	20	2026-08-18 11:55:59.83
27	delivery	net_total@delivery:party+type	671.300000	1036.025000	796.897500	0.000000	3779.375000	30	2026-08-18 11:55:59.841
65	production	roll_weight	27.600000	3.400000	2.520420	17.400000	37.800000	1271	2026-08-19 04:25:30.968
28	delivery	net_total@delivery:party+gsm_band	683.675000	1264.075000	827.957970	0.000000	4475.900000	28	2026-08-18 11:55:59.871
29	delivery	net_total@delivery:type+gsm_band	683.275000	1452.737500	895.082685	0.000000	5041.487500	28	2026-08-18 11:55:59.877
30	delivery	net_total@delivery:date+party	990.450000	2216.950000	897.936690	0.000000	7641.300000	23	2026-08-18 11:55:59.888
31	delivery	net_total@delivery:date+party+type	671.300000	1036.025000	796.897500	0.000000	3779.375000	30	2026-08-18 11:55:59.895
66	production	total_weight	195.300000	87.025000	65.827440	0.000000	456.375000	191	2026-08-19 04:25:30.975
67	production	total_weight@date	2043.950000	615.850000	469.354095	196.400000	3891.500000	18	2026-08-19 04:25:30.981
68	production	total_weight@shift	1011.150000	336.675000	262.864980	1.125000	2021.175000	35	2026-08-19 04:25:30.992
69	production	total_weight@machine	369.375000	190.850000	144.071655	0.000000	941.925000	98	2026-08-19 04:25:31.001
70	production	total_weight@employee	410.350000	259.575000	193.256910	0.000000	1189.075000	84	2026-08-19 04:25:31.013
71	production	total_weight@date+shift	1011.150000	336.675000	262.864980	1.125000	2021.175000	35	2026-08-19 04:25:31.021
72	production	total_weight@date+machine	369.375000	190.850000	144.071655	0.000000	941.925000	98	2026-08-19 04:25:31.031
21	delivery	net_weight	672.600000	1238.150000	848.862630	0.000000	4387.050000	41	2026-08-18 11:55:59.781
22	delivery	quantity	25.000000	43.000000	32.617200	0.000000	154.000000	41	2026-08-18 11:55:59.79
23	delivery	gsm	250.000000	5.000000	7.413000	235.000000	265.000000	26	2026-08-18 11:55:59.799
24	delivery	wt_per_roll	26.872000	3.324074	2.348438	16.899778	36.844222	41	2026-08-18 11:55:59.807
25	delivery	net_total@delivery:party	990.450000	2216.950000	897.936690	0.000000	7641.300000	23	2026-08-18 11:55:59.817
80	production	total_weight@date+machine+employee	195.050000	81.925000	61.898550	0.000000	440.825000	183	2026-08-19 04:25:31.179
81	production	total_weight@date+machine+party	370.050000	207.750000	152.337150	0.000000	993.300000	105	2026-08-19 04:25:31.189
82	production	total_weight@date+employee+party	220.800000	224.450000	107.266110	0.000000	894.150000	141	2026-08-19 04:25:31.198
83	production	total_weight@shift+machine+employee	195.050000	81.925000	61.898550	0.000000	440.825000	183	2026-08-19 04:25:31.212
84	production	total_weight@shift+machine+party	195.300000	86.150000	64.863750	0.000000	453.750000	189	2026-08-19 04:25:31.225
85	production	total_weight@shift+employee+party	220.800000	224.450000	107.266110	0.000000	894.150000	141	2026-08-19 04:25:31.236
86	production	total_weight@machine+employee+party	195.300000	86.150000	64.863750	0.000000	453.750000	189	2026-08-19 04:25:31.244
87	production	total_weight@date+shift+machine+employee	195.050000	81.925000	61.898550	0.000000	440.825000	183	2026-08-19 04:25:31.276
88	production	total_weight@date+shift+machine+party	195.300000	86.150000	64.863750	0.000000	453.750000	189	2026-08-19 04:25:31.291
89	production	total_weight@date+shift+employee+party	220.800000	224.450000	107.266110	0.000000	894.150000	141	2026-08-19 04:25:31.32
90	production	total_weight@date+machine+employee+party	195.300000	86.150000	64.863750	0.000000	453.750000	189	2026-08-19 04:25:31.329
91	production	total_weight@shift+machine+employee+party	195.300000	86.150000	64.863750	0.000000	453.750000	189	2026-08-19 04:25:31.338
92	production	total_weight@date+shift+machine+employee+party	195.300000	86.150000	64.863750	0.000000	453.750000	189	2026-08-19 04:25:31.347
73	production	total_weight@date+employee	410.350000	259.575000	193.256910	0.000000	1189.075000	84	2026-08-19 04:25:31.046
74	production	total_weight@shift+machine	195.050000	81.925000	61.898550	0.000000	440.825000	183	2026-08-19 04:25:31.062
75	production	total_weight@shift+employee	410.350000	259.575000	193.256910	0.000000	1189.075000	84	2026-08-19 04:25:31.072
76	production	total_weight@machine+employee	195.050000	81.925000	61.898550	0.000000	440.825000	183	2026-08-19 04:25:31.081
77	production	total_weight@machine+party	370.050000	207.750000	152.337150	0.000000	993.300000	105	2026-08-19 04:25:31.09
78	production	total_weight@date+shift+machine	195.050000	81.925000	61.898550	0.000000	440.825000	183	2026-08-19 04:25:31.151
79	production	total_weight@date+shift+employee	410.350000	259.575000	193.256910	0.000000	1189.075000	84	2026-08-19 04:25:31.165
\.


--
-- Data for Name: plausibility_feedback; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.plausibility_feedback (id, operation, field, entered_value, expected_low, expected_high, outcome, created_by, created_at) FROM stdin;
1	production	roll_weight	16.350000	18.650000	37.250000	confirmed_anyway	Iftikhar	2026-08-12 05:22:38.934038
2	production	roll_weight	17.300000	18.650000	37.250000	confirmed_anyway	Iftikhar	2026-08-12 05:22:38.934038
3	production	roll_weight	16.750000	18.500000	37.400000	confirmed_anyway	Iftikhar	2026-08-12 05:23:29.030921
4	production	roll_weight	16.250000	18.600000	37.200000	confirmed_anyway	Iftikhar	2026-08-12 05:28:07.098999
5	production	roll_weight	9.350000	18.625000	37.375000	confirmed_anyway	Iftikhar	2026-08-13 04:46:55.552839
6	production	roll_weight	14.000000	18.625000	37.375000	confirmed_anyway	Iftikhar	2026-08-13 04:48:05.643428
7	production	roll_weight	9.350000	18.550000	37.450000	confirmed_anyway	Iftikhar Ahmed	2026-08-15 05:54:52.389743
8	delivery	gsm	145.000000	235.000000	265.000000	confirmed_anyway	Tahir Hassan	2026-08-15 11:00:36.449669
9	delivery	wt_per_roll	5.200000	17.040000	36.601000	confirmed_anyway	Tahir Hassan	2026-08-15 11:00:36.449669
10	delivery	gsm	145.000000	235.000000	265.000000	confirmed_anyway	Tahir Hassan	2026-08-15 11:01:03.177541
11	delivery	wt_per_roll	5.200000	17.040000	36.601000	confirmed_anyway	Tahir Hassan	2026-08-15 11:01:03.177541
12	production	roll_weight	16.000000	18.338000	37.463000	confirmed_anyway	Iftikhar Ahmed	2026-08-17 05:23:30.422533
13	production	roll_weight	13.100000	18.338000	37.463000	confirmed_anyway	Iftikhar Ahmed	2026-08-17 05:23:30.422533
14	delivery	gsm	340.000000	235.000000	265.000000	confirmed_anyway	Iftikhar Ahmed	2026-08-17 07:19:50.745392
15	delivery	gsm	340.000000	235.000000	265.000000	confirmed_anyway	Iftikhar Ahmed	2026-08-17 07:20:44.927645
16	delivery	gsm	140.000000	235.000000	265.000000	confirmed_anyway	Iftikhar Ahmed	2026-08-18 11:55:08.282185
17	delivery	wt_per_roll	10.000000	17.312000	36.496000	confirmed_anyway	Iftikhar Ahmed	2026-08-18 11:55:08.282185
18	receipt	wt_per_bag	36.000000	36.202000	54.518000	confirmed_anyway	Iftikhar Ahmed	2026-08-19 11:32:20.780862
19	receipt	wt_per_bag	36.000000	43.653000	47.067000	confirmed_anyway	Iftikhar Ahmed	2026-08-19 11:35:52.323029
\.


--
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.role (id, name, is_admin, created_at) FROM stdin;
1	Admin	t	2026-08-13 19:58:33.532958
2	Manager	f	2026-08-13 19:58:33.53682
3	Supervisor	f	2026-08-13 19:58:33.53832
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

COPY public.salary_detail (id, header_id, employee_id, month, year, department_id, employee_name, basic_salary, ot_rate_hr, att_allowance, oth_allowance, present_days, absent_days, holidays, total_attendance, total_salary, ot_hours, ot_amount, advance_deduction, loan_deduction, other_deduction, payable_salary) FROM stdin;
\.


--
-- Data for Name: salary_header; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.salary_header (id, month, year, department_ids, posted, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: transaction_detail; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transaction_detail (id, header_id, quantity, net_wt, machine_id, employee_id, yarn_type_id, yarn_count_id, yarn_brand_id, uom_id) FROM stdin;
713	215	60.000	1564.400	\N	\N	20	23	3	1
718	219	5.000	117.000	\N	\N	24	13	3	1
719	220	1.000	5.200	\N	\N	22	13	3	1
720	220	1.000	24.800	\N	\N	20	23	3	1
714	216	26.000	718.900	\N	\N	24	13	3	1
715	217	10.000	270.650	\N	\N	20	23	3	1
721	221	1.000	400.950	\N	\N	\N	2	2	1
722	222	13.000	318.500	\N	\N	\N	19	18	1
496	153	6.000	179.750	25	1	20	28	1	1
497	153	8.000	236.350	25	9	20	28	1	1
498	153	9.000	259.400	14	8	20	28	1	1
499	153	10.000	259.750	14	2	20	28	1	1
500	153	9.000	256.400	15	8	20	28	1	1
501	153	10.000	265.750	15	2	20	28	1	1
506	155	7.000	175.000	25	1	20	42	1	1
507	155	6.000	158.600	25	9	20	42	1	1
508	155	9.000	281.750	14	8	20	42	1	1
509	155	9.000	269.050	14	9	20	42	1	1
510	155	9.000	266.150	15	8	20	42	1	1
511	155	10.000	276.350	15	2	20	42	1	1
518	157	14.000	635.040	\N	\N	20	2	2	1
520	159	25.000	1134.000	\N	\N	20	2	2	1
521	159	28.000	1270.080	\N	\N	20	1	20	1
527	163	37.000	990.450	\N	\N	20	23	1	1
653	196	23.000	828.000	\N	\N	20	41	18	1
557	151	34.000	1542.240	\N	\N	\N	1	1	1
540	136	4.000	102.700	18	7	20	26	3	1
541	136	1.000	23.800	18	2	20	26	3	1
542	136	8.000	199.350	21	1	24	39	3	1
543	136	7.000	209.700	21	9	24	39	3	1
558	151	12.000	432.000	\N	\N	\N	41	18	1
547	166	6.000	153.900	23	7	20	23	1	1
548	166	8.000	206.900	23	2	20	23	1	1
549	166	5.000	135.550	24	1	20	23	1	1
550	166	6.000	175.450	24	9	20	23	1	1
559	151	50.000	2268.000	\N	\N	\N	17	1	1
616	168	54.000	2442.290	\N	\N	\N	1	1	\N
570	172	1.000	5.300	\N	\N	22	13	3	1
571	172	1.000	9.500	\N	\N	24	13	3	1
572	172	19.000	561.250	\N	\N	24	13	3	1
573	172	14.000	401.700	\N	\N	20	26	13	1
574	172	1.000	11.800	\N	\N	22	13	3	1
575	172	4.000	100.050	\N	\N	24	13	3	1
577	174	58.000	1721.300	\N	\N	20	28	1	1
578	174	59.000	1717.850	\N	\N	20	28	1	1
580	176	50.000	1422.800	\N	\N	20	28	1	1
581	176	59.000	1663.250	\N	\N	20	28	1	1
583	178	25.000	672.600	\N	\N	20	23	2	1
586	180	25.000	671.800	\N	\N	20	23	2	1
617	168	33.000	1478.100	\N	\N	\N	17	1	\N
590	147	6.000	145.050	23	7	20	23	2	1
591	147	8.000	212.750	23	2	20	23	2	1
593	146	7.000	184.350	23	7	20	23	2	1
594	146	7.000	190.000	23	2	20	23	2	1
595	146	2.000	53.100	24	1	20	23	2	1
596	146	6.000	171.500	24	9	20	23	2	1
608	181	1.000	2675.056	\N	\N	20	23	2	\N
611	164	1.000	7436.424	\N	\N	20	29	1	1
613	183	1.000	706.962	\N	\N	20	29	3	\N
615	185	1.000	50.764	\N	\N	20	37	1	1
618	186	6.000	167.050	22	2	20	23	2	1
619	186	6.000	155.300	23	7	20	23	2	1
620	186	8.000	213.350	23	2	20	23	2	1
621	186	5.000	125.100	24	1	20	23	2	1
622	186	8.000	208.350	24	9	20	23	2	1
628	188	8.000	234.900	25	1	20	42	1	1
629	188	9.000	241.450	25	9	20	42	1	1
630	188	10.000	278.300	14	8	20	42	1	1
631	188	10.000	276.100	14	9	20	42	1	1
632	188	9.000	261.850	15	8	20	42	1	1
633	188	10.000	277.000	15	2	20	42	1	1
639	190	42.000	1116.150	\N	\N	20	23	2	1
645	182	1.000	4466.360	\N	\N	20	26	1	1
654	139	6.000	161.050	22	8	20	23	2	1
655	139	5.000	153.250	22	9	20	23	2	1
656	139	7.000	167.900	23	7	20	23	2	1
657	139	8.000	194.200	23	2	20	23	2	1
661	197	7.000	143.500	22	7	20	23	2	1
662	197	3.000	91.500	22	2	20	23	2	1
663	197	4.000	108.200	24	1	20	23	2	1
670	199	6.000	150.600	\N	\N	24	13	3	1
672	200	8.000	176.450	\N	\N	22	17	1	1
646	193	1.000	309.350	\N	18	24	39	3	1
647	193	1.000	1809.200	\N	18	20	26	3	1
648	193	1.000	17.900	\N	18	22	13	3	1
674	202	1.000	2100.900	25	18	20	28	1	2
685	207	1.000	183.500	25	18	20	32	3	1
568	170	20.000	498.150	\N	\N	20	23	2	1
726	224	49.000	1388.750	\N	\N	20	42	1	1
727	224	51.000	1429.200	\N	\N	20	42	1	1
641	191	36.000	1011.850	\N	\N	20	42	1	1
642	191	49.000	1391.000	\N	\N	20	42	1	1
484	150	6.000	171.050	25	1	20	28	1	1
485	150	7.000	194.200	25	9	20	28	1	1
486	150	9.000	252.800	14	8	20	28	1	1
487	150	8.000	266.050	14	9	20	28	1	1
488	150	7.000	210.150	15	8	20	28	1	1
489	150	9.000	275.650	15	2	20	28	1	1
643	191	27.000	759.350	\N	\N	20	42	1	1
698	209	47.000	1137.500	\N	\N	20	23	2	1
502	154	5.000	149.250	23	7	20	23	1	1
503	154	8.000	198.600	23	2	20	23	1	1
504	154	5.000	130.050	24	1	20	23	1	1
505	154	7.000	194.700	24	9	20	23	1	1
519	158	100.000	4536.000	\N	\N	24	13	3	1
526	162	47.000	1233.900	\N	\N	20	23	2	1
528	132	6.000	162.300	25	1	20	29	1	1
529	132	7.000	206.400	25	3	20	29	1	1
530	132	3.000	88.300	14	8	20	29	1	1
531	132	9.000	251.200	14	9	20	29	1	1
532	132	6.000	156.150	15	8	20	29	1	1
533	132	4.000	116.150	15	2	20	29	1	1
538	140	6.000	148.450	24	1	20	23	1	1
539	140	7.000	202.400	24	3	20	23	1	1
429	133	7.000	201.300	25	8	20	29	1	1
430	133	7.000	211.350	25	9	20	29	1	1
431	133	9.000	266.800	14	8	20	29	1	1
432	133	8.000	243.450	14	9	20	29	1	1
433	133	6.000	174.650	15	7	20	29	1	1
434	133	2.000	56.250	15	2	20	29	1	1
435	134	6.000	167.450	25	1	20	29	1	1
436	134	7.000	209.500	25	9	20	29	1	1
437	134	9.000	256.700	14	8	20	29	1	1
438	134	8.000	252.600	14	9	20	29	1	1
439	134	5.000	157.150	15	8	20	29	1	1
440	134	8.000	223.800	15	2	20	29	1	1
441	135	7.000	148.400	18	7	20	26	19	1
442	135	4.000	104.600	18	2	20	26	19	1
447	137	2.000	39.700	18	2	20	29	1	1
448	138	6.000	174.900	21	1	24	39	3	1
449	138	8.000	230.400	21	9	24	39	3	1
456	141	6.000	150.750	22	8	20	23	2	1
457	141	4.000	108.150	22	2	20	23	2	1
458	141	7.000	186.200	23	7	20	23	2	1
459	141	8.000	184.950	23	2	20	23	2	1
460	142	6.000	167.550	24	1	20	23	1	1
461	142	3.000	91.150	24	9	20	23	1	1
462	143	5.000	119.150	18	7	20	26	3	1
463	143	5.000	127.000	18	2	20	26	3	1
464	143	7.000	192.450	21	1	20	26	3	1
465	143	8.000	218.350	21	9	20	26	3	1
466	144	3.000	89.850	22	8	20	23	2	1
467	144	6.000	162.350	23	7	20	23	2	1
468	144	8.000	199.600	23	2	20	23	2	1
551	167	6.000	177.600	25	1	20	42	1	1
552	167	9.000	244.500	25	9	20	42	1	1
553	167	8.000	217.250	14	8	20	42	1	1
554	167	10.000	281.400	14	9	20	42	1	1
555	167	7.000	193.950	15	7	20	42	1	1
556	167	10.000	280.200	15	2	20	42	1	1
569	171	2.000	39.700	\N	\N	\N	\N	\N	\N
576	173	18.000	439.850	\N	\N	20	26	19	1
579	175	15.000	384.800	\N	\N	20	23	2	1
582	177	22.000	599.300	\N	\N	20	23	2	1
584	179	52.000	1514.900	\N	\N	20	42	1	1
585	179	52.000	1518.400	\N	\N	20	42	1	1
612	165	1.000	1908.837	\N	\N	20	23	3	1
614	184	1.000	455.460	\N	\N	20	29	1	1
623	187	6.000	173.350	25	1	20	42	1	1
624	187	10.000	285.950	14	1	20	42	1	1
625	187	3.000	86.600	14	9	20	42	1	1
626	187	9.000	262.550	15	7	20	42	1	1
627	187	9.000	254.400	15	9	20	42	1	1
634	189	9.000	189.300	22	7	20	23	2	1
635	189	7.000	173.250	22	9	20	23	2	1
636	189	8.000	197.500	23	7	20	23	2	1
637	189	8.000	227.150	24	1	20	23	2	1
638	189	8.000	212.000	24	9	20	23	2	1
644	192	108.000	4898.880	\N	\N	20	2	3	1
658	160	11.000	498.960	\N	\N	20	2	2	1
659	160	12.000	432.000	\N	\N	20	19	18	1
660	160	28.000	1270.080	\N	\N	20	1	15	1
664	198	5.000	137.800	25	1	20	28	1	1
665	198	8.000	232.250	25	9	20	28	1	1
666	198	6.000	175.050	14	1	20	28	1	1
667	198	10.000	271.300	14	9	20	28	1	1
668	198	9.000	234.850	15	7	20	28	1	1
669	198	9.000	238.100	15	2	20	28	1	1
675	203	8.000	228.900	25	1	20	28	1	1
676	203	9.000	241.800	25	9	20	28	1	1
677	203	10.000	284.750	14	8	20	28	1	1
678	203	11.000	300.500	14	9	20	28	1	1
679	203	10.000	272.000	15	8	20	28	1	1
680	203	10.000	258.350	15	2	20	28	1	1
683	205	1.000	16.750	22	7	20	23	1	1
525	161	27.000	694.750	\N	\N	20	23	2	1
723	223	24.000	777.650	\N	\N	\N	20	18	1
724	223	1.000	27.250	\N	\N	\N	2	1	1
725	223	1.000	4.550	\N	\N	\N	1	1	1
692	208	8.000	224.000	25	1	20	42	1	1
693	208	7.000	183.200	25	9	20	42	1	1
694	208	9.000	276.350	14	8	20	42	1	1
695	208	5.000	137.650	14	9	20	42	1	1
696	208	9.000	265.450	15	8	20	42	1	1
697	208	8.000	229.950	15	2	20	42	1	1
711	214	7.000	204.900	15	8	20	42	1	1
712	214	7.000	192.550	15	2	20	42	1	1
560	152	30.000	1360.800	\N	\N	20	1	1	1
561	152	17.000	612.000	\N	\N	20	41	18	1
562	152	29.000	1278.310	\N	\N	20	17	1	1
649	194	121.000	3993.000	\N	\N	20	19	18	1
651	195	31.000	1023.000	\N	\N	2	19	18	1
652	195	45.000	1485.000	\N	\N	2	19	18	1
567	169	127.000	5760.720	\N	\N	20	1	1	1
673	201	1.000	694.750	22	18	20	23	2	1
684	206	1.000	372.450	25	18	20	23	1	1
716	218	56.000	1549.050	\N	\N	20	42	1	1
717	218	50.000	1377.550	\N	\N	20	42	1	1
728	225	1.000	7.600	\N	\N	\N	17	1	1
729	225	1.000	5.150	\N	\N	\N	17	1	1
730	225	1.000	32.000	\N	\N	\N	41	18	1
731	225	5.000	180.000	\N	\N	\N	41	18	1
742	227	8.000	228.800	25	1	20	23	3	1
743	227	9.000	244.000	25	9	20	23	3	1
744	227	8.000	220.800	14	8	20	23	3	1
745	227	9.000	236.800	14	2	20	23	3	1
746	227	7.000	160.800	18	7	20	23	3	1
747	227	7.000	206.750	18	2	20	23	3	1
748	227	6.000	149.400	21	1	23	39	3	1
749	227	7.000	160.600	21	9	23	39	3	1
732	226	7.000	195.300	25	1	20	23	3	1
733	226	9.000	247.850	25	9	20	23	3	1
734	226	7.000	190.950	14	8	20	23	3	1
735	226	9.000	244.550	14	9	20	23	3	1
736	226	2.000	54.600	15	8	20	23	3	1
737	226	8.000	189.950	15	2	20	23	3	1
738	226	6.000	176.050	18	7	20	23	3	1
739	226	7.000	202.800	18	2	20	23	3	1
740	226	4.000	103.400	19	7	20	23	3	1
741	226	6.000	150.650	21	9	23	39	3	1
702	212	1.000	19.100	25	1	20	23	3	1
703	212	9.000	249.050	25	9	20	23	3	1
704	212	1.000	27.900	14	8	20	23	3	1
705	212	9.000	239.050	14	9	20	23	3	1
706	212	2.000	52.400	18	7	20	23	3	1
707	212	7.000	203.600	18	2	20	23	3	1
708	212	1.000	20.650	20	7	20	23	3	1
709	213	8.000	213.800	19	7	22	13	3	1
710	213	8.000	243.450	19	2	22	13	3	1
699	210	6.000	159.400	18	7	20	23	3	1
700	211	4.000	85.950	19	7	22	13	3	1
701	211	10.000	269.700	19	2	22	13	3	1
686	204	5.000	130.100	18	7	20	26	1	1
687	204	5.000	142.000	18	2	20	26	1	1
688	204	4.000	116.650	19	7	22	13	1	1
689	204	7.000	211.250	19	2	22	13	1	1
690	204	2.000	33.650	21	1	24	13	1	1
691	204	3.000	83.350	21	9	24	13	1	1
481	148	1.000	15.100	18	7	20	26	1	1
750	228	9.000	243.150	25	1	20	23	1	1
751	228	9.000	236.800	25	9	20	23	1	1
752	228	9.000	231.800	14	8	20	23	1	1
753	228	9.000	234.850	14	2	20	23	1	1
754	228	8.000	195.050	18	7	20	23	1	1
755	228	6.000	176.200	18	2	20	23	1	1
756	229	8.000	167.100	21	1	23	39	3	1
757	229	7.000	160.800	21	9	23	39	3	1
758	230	9.000	246.800	25	1	20	23	3	1
759	230	9.000	239.700	25	9	20	23	3	1
760	230	9.000	233.250	14	8	20	23	3	1
761	230	9.000	231.550	14	2	20	23	3	1
762	230	5.000	123.300	15	8	20	23	3	1
763	230	7.000	189.000	18	7	20	23	3	1
764	230	7.000	206.950	18	2	20	23	3	1
765	231	7.000	163.650	21	1	23	28	3	1
766	231	7.000	173.550	21	9	23	28	3	1
767	232	2.000	38.850	15	8	20	23	3	1
768	233	9.000	243.300	\N	\N	20	23	1	1
769	234	1.000	10.000	\N	\N	22	13	3	1
770	235	2.000	42.100	\N	\N	23	39	3	1
\.


--
-- Data for Name: transaction_header; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transaction_header (id, transaction_type_id, date, doc_number, job_id, party_id, location_id, fabric_type_id, sl, gsm, reference) FROM stdin;
153	5	2026-08-06	20260806	15	14	18	13	\N	\N	\N
155	5	2026-08-05	20260805	15	14	\N	13	\N	\N	\N
157	3	2026-08-03	169827	13	13	\N	13	\N	\N	\N
159	3	2026-08-06	169950	13	13	\N	13	\N	\N	\N
163	6	2026-08-03	3737	16	15	\N	13	\N	\N	\N
167	5	2026-08-07	20260807	15	14	\N	13	\N	\N	\N
234	6	2026-08-18	3774	14	16	\N	1	\N	\N	Style#158374
171	6	2026-08-04	3739	\N	20	\N	13	\N	\N	\N
173	6	2026-08-04	3743	17	17	\N	13	\N	\N	\N
175	6	2026-08-05	3746	13	13	\N	13	\N	\N	\N
177	6	2026-08-06	3749	13	13	\N	13	\N	\N	\N
179	6	2026-08-07	3751,3752	15	14	\N	13	\N	\N	\N
147	5	2026-08-04	20260804	13	13	\N	13	\N	\N	\N
181	3	2026-07-31	August-26 >----> Opening	\N	13	\N	13	\N	\N	August-26 >----> Opening
165	3	2026-07-31	August-26 >----> Opening	16	15	\N	13	\N	\N	August-26 >----> Opening
183	3	2026-07-31	August-26 >----> Opening	\N	17	\N	13	\N	\N	August-26 >----> Opening
185	3	2026-07-31	August-26 >----> Opening	\N	19	\N	13	\N	\N	August-26 >----> Opening
187	5	2026-08-09	20260809	15	14	\N	13	\N	\N	\N
189	5	2026-08-09	20260809	13	13	\N	13	\N	\N	\N
197	5	2026-08-10	20260810	13	13	\N	13	\N	\N	\N
199	6	2026-08-10	3758	14	16	\N	4	1160	\N	\N
203	5	2026-08-11	20260811	15	14	\N	13	\N	\N	\N
205	5	2026-08-11	20260811	13	13	\N	13	\N	\N	\N
214	5	2026-08-13	4700015016	15	14	\N	13	940+640+384	340	\N
220	6	2026-08-13	3770	14	16	\N	13	1000+740+380	240	3770
216	6	2026-08-11	3761	14	16	\N	4	1160	245	3761
191	6	2026-08-10	3755,3756,3757	15	14	\N	13	940+640+384	\N	3755,3756,3757
209	6	2026-08-11	3759	13	13	\N	13	960+720+370	\N	3759 
161	6	2026-08-01	3735	13	13	\N	13	960+720+370	\N	3735
222	4	2026-08-11	3764	13	13	\N	\N	\N	\N	3764
151	3	2026-08-05	4700015011	\N	14	\N	13	\N	\N	4700015011
195	4	2026-08-01	20260801-1	14	16	\N	\N	\N	\N	20260801-1
193	5	2026-07-31	August-26 >----> Opening	\N	16	\N	13	\N	\N	August-26 >----> Opening
169	3	2026-08-04	852	14	16	\N	13	\N	\N	\N
201	5	2026-07-31	Actions August-26 >----> Opening	13	13	\N	13	\N	\N	Actions August-26 >----> Opening
207	5	2026-07-31	August-26 >----> Opening	17	17	\N	13	\N	\N	August-26 >----> Opening
218	6	2026-08-13	3767,3768	15	14	\N	13	940+640+384	340	3767,3768
224	6	2026-08-17	3771,3772	15	14	\N	13	940+640+384	240	3771,3772
227	5	2026-08-16	20260816	14	16	\N	13	\N	\N	20260816
226	5	2026-08-15	20260815	14	16	\N	13	\N	\N	20260815
212	5	2026-08-13	20260813	14	16	\N	13	1000+710+380	240	20260813
210	5	2026-08-12	20260812	14	16	\N	13	1000+710+380	240	20260812
229	5	2026-08-17	20260817	14	16	\N	16	\N	\N	\N
232	5	2026-08-18	20260818	17	17	\N	13	\N	\N	\N
150	5	2026-08-04	20260804	15	14	\N	13	\N	\N	\N
154	5	2026-08-06	20260808	13	13	\N	13	\N	\N	\N
158	3	2026-08-04	0268	14	16	\N	4	\N	\N	\N
162	6	2026-08-03	3736	13	13	\N	13	960+720+370	\N	\N
132	5	2026-08-01	20260801-01	15	14	13	13	\N	\N	20260801-01
140	5	2026-08-01	20260801-01	16	15	\N	13	\N	\N	20260801-01
136	5	2026-08-02	20260802-01	14	16	\N	13	\N	\N	20260802-01
166	5	2026-08-07	20260807	13	13	\N	13	960+720+370	\N	\N
194	3	2026-08-01	20260801-1	\N	16	\N	13	\N	\N	20260801-1
133	5	2026-08-02	20260802-01	15	14	\N	13	\N	\N	20260802-01
134	5	2026-08-03	20260803-01	15	14	\N	13	\N	\N	20260803-01
135	5	2026-08-01	20260801-01	17	17	\N	13	\N	\N	20260801-01
137	5	2026-08-01	20260801-01	\N	20	\N	13	\N	\N	20260802-01
138	5	2026-08-01	20260801-01	14	16	\N	4	\N	\N	20260801-01
141	5	2026-08-02	20260802-01	13	13	\N	13	\N	\N	20260802-01
142	5	2026-08-02	20260802-01	16	15	\N	13	\N	\N	20260802-01
143	5	2026-08-03	20260803-01	14	16	\N	13	\N	\N	20260803-01
144	5	2026-08-03	20260803-01	13	13	\N	13	\N	\N	20260803-01
202	5	2026-07-31	August-26 >----> Opening	15	14	\N	13	\N	\N	August-26 >----> Opening
172	6	2026-08-04	3740,3741,3742	\N	16	\N	13	\N	\N	\N
174	6	2026-08-05	3744,3745	15	14	\N	13	\N	\N	\N
176	6	2026-08-06	3747,3748	15	14	\N	13	\N	\N	\N
178	6	2026-08-07	3750	13	13	\N	13	\N	\N	\N
180	6	2026-08-08	3753	13	13	\N	13	\N	\N	\N
206	5	2026-07-31	August-26 >----> Opening	16	15	\N	13	\N	\N	August-26 >----> Opening
146	5	2026-08-05	20260805	13	13	\N	13	\N	\N	\N
170	6	2026-08-04	3738	13	13	\N	13	\N	\N	\N
225	4	2026-08-17	3773	15	14	\N	13	\N	\N	3773
213	5	2026-08-13	20260813	14	16	\N	1	820	140	20260813
211	5	2026-08-12	20260812	14	16	\N	1	820	140	20260812
204	5	2026-08-11	20260811-1	14	16	\N	13	\N	\N	20260811-1
148	5	2026-08-04	20260804	14	16	\N	13	\N	\N	20260804
164	3	2026-07-31	August-26 >----> Opening	\N	14	\N	13	\N	\N	August-26 >----> Opening
184	3	2026-07-31	August-26 >----> Opening	\N	20	\N	13	\N	\N	August-26 >----> Opening
228	5	2026-08-17	4700015017	14	16	\N	13	\N	\N	\N
186	5	2026-08-08	20260808	13	13	\N	13	\N	\N	\N
188	5	2026-08-08	20260808	15	14	\N	13	\N	\N	\N
190	6	2026-08-10	3754	13	13	\N	13	\N	\N	\N
192	3	2026-08-10	0320	14	16	\N	13	\N	\N	\N
182	3	2026-07-31	August-26 >----> Opening	\N	16	\N	4	\N	\N	August-26 >----> Opening
139	5	2026-08-01	20260801-01	13	13	\N	13	\N	\N	20260801-01
160	3	2026-08-01	169808	13	13	\N	13	\N	\N	\N
198	5	2026-08-10	20260810	15	14	\N	13	\N	\N	\N
200	6	2026-08-01	3734	\N	20	\N	1	\N	\N	3734
230	5	2026-08-18	20260818	14	16	\N	13	\N	\N	\N
208	5	2026-08-12	20260812	15	14	\N	13	940+640+384	340	\N
215	6	2026-08-11	3760	14	16	\N	13	1060+730+410	200	3760
219	6	2026-08-13	3769	14	16	\N	4	1160	240	3769
217	6	2026-08-11	3762	14	16	\N	13	1060+730+410	200	3762
221	4	2026-08-11	3763	13	13	\N	\N	\N	\N	3763
223	4	2026-08-15	3766	15	14	\N	\N	\N	\N	3766
196	3	2026-08-05	4700015011	15	14	18	13	\N	\N	4700015011
152	3	2026-08-03	4700014961	15	14	18	13	\N	\N	4700014961
168	3	2026-08-06	4700015011	15	14	\N	13	\N	\N	4700015011
231	5	2026-08-18	20260818	14	16	\N	16	\N	\N	\N
233	6	2026-08-18	3774	14	16	\N	13	1000+700+385	368	Style#158374
235	6	2026-08-18	3774	14	16	\N	16	820	\N	Style#158374
\.


--
-- Data for Name: transaction_type_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transaction_type_master (id, name, code, action) FROM stdin;
7	Fabric Delivery Return	Fabric_Delivery_Return	Plus
3	Yarn Receipt	Yarn_Receipt	Plus
4	Yarn Return	Yarn_Return	Minus
6	Fabric Delivery	Fabric_Dispatch	Minus
5	Fabric Production	Fabric_Production	\N
\.


--
-- Data for Name: uom_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.uom_master (id, name, abbreviation) FROM stdin;
3	Meter	MTR
1	KG	KG
2	GM	GM
4	PCS	PCS
\.


--
-- Data for Name: yarn_brand_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yarn_brand_master (id, name, code) FROM stdin;
2	Premium	Premium
3	Faisal	Faisal
1	Gadoon	Gadoon
4	Tata	Tata
13	Fazal	Fazal
14	Gul Ahmed	Gul Ahmed
15	Metco	Metco
16	Ibrahim Fiber	Ibrahim
17	Feroze	Feroze
18	CHINA	CHINA
19	Shahzad	Shahzad
20	Relince 	Relince 
\.


--
-- Data for Name: yarn_count_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yarn_count_master (id, name, count) FROM stdin;
19	75/36	75/36
20	50/36	50/36
21	40-D	40-D
22	70-D	70-D
37	20s+70-D Lycra	20s+70-D Lycra
38	30s+40-D Lycra	30s+40-D Lycra
39	20s+40-D Lycra	20s+40-D Lycra
36	30s+70-D Lyc 1.5 Tar	30s+70-D Lyc 1.5 Tar
40	30s+70-D Lyc D.Tar	30s+70-D Lyc D.Tar
1	10s	10s
15	16s	16s
13	20s	20s
33	20s+50/36+10s	20s+50/36+10s
35	20s+50/36+16s	20s+50/36+16s
31	20s+75/36+10s	20s+75/36+10s
32	20s+75/36+16s	20s+75/36+16s
16	24s	24s
17	26s	26s
2	30s	30s
29	30s+50/36+16s	30s+50/36+16s
28	30s+50/36+10s	30s+50/36+10s
30	30s+50/36+20s	30s+50/36+20s
23	30s+75/36+10s	30s+75/36+10s
26	30s+75/36+16s	30s+75/36+16s
27	30s+75/36+20s	30s+75/36+20s
18	32s	32s
3	40s	40s
4	60s	60s
14	08s	08s
41	100/36	100/36
43	100/20	100/20
45	30s+30s+16s	30s+30s+16s
46	30s+30s+10s	30s+30s+10s
47	20s+50/36+12s	20s+50/36+12s
48	30s+75/36+12s	30s+75/36+12s
49	30s+50/36+12s	30s+50/36+12s
42	26s+100/36+10s	26s+100/36+10s
\.


--
-- Data for Name: yarn_receipt_detail; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yarn_receipt_detail (id, header_id, yarn_count_id, quantity, net_weight, yarn_brand_id) FROM stdin;
3	3	2	11	498.960	2
4	3	19	12	432.000	18
5	3	1	28	1270.080	15
6	4	2	14	635.040	2
13	7	13	100	4536.000	3
15	9	2	25	1134.000	2
16	9	1	28	1270.080	20
17	5	1	30	1360.800	1
18	5	19	17	612.000	18
19	5	17	29	1278.310	1
20	6	1	34	1542.240	1
21	6	19	12	432.000	18
22	6	17	50	2268.000	1
23	10	1	127	5760.720	1
26	12	26	1	4466.360	1
31	13	23	1	1908.837	3
34	14	29	1	7436.424	1
35	15	29	1	706.962	3
37	11	23	1	2675.056	2
38	16	29	1	455.460	1
41	17	1	54	2442.290	1
42	17	17	33	1478.100	1
43	18	37	1	50.764	1
44	19	2	108	4898.880	3
45	20	19	121	3993.000	18
46	21	41	23	828.000	18
47	22	13	14	635.040	4
48	23	19	8	288.000	18
50	24	1	25	1134.000	15
51	24	19	3	108.000	18
\.


--
-- Data for Name: yarn_receipt_header; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yarn_receipt_header (id, receipt_date, party_id, status, created_by, created_at, updated_by, updated_at, reconciled, reconciled_transaction_id, reconciled_at, doc_number) FROM stdin;
6	2026-08-05	14	submitted	Iftikhar 	2026-08-06 07:04:15.540986	Iftikhar 	2026-08-06 13:25:13.63	t	151	2026-08-06 13:29:06.366	47*15011
5	2026-08-03	14	submitted	Iftikhar 	2026-08-06 07:00:54.830412	Iftikhar 	2026-08-06 13:24:52.614	t	152	2026-08-06 13:30:37.422	47*14961
4	2026-08-03	13	submitted	Iftikhar 	2026-08-05 15:17:31.325144	\N	2026-08-05 15:17:31.325144	t	157	2026-08-07 09:28:55.475	169827
7	2026-08-04	16	submitted	Iftikhar 	2026-08-06 12:06:12.637753	\N	2026-08-06 12:06:12.637753	t	158	2026-08-07 09:39:44.079	0268
10	2026-08-04	16	submitted	Iftikhar 	2026-08-07 05:50:24.91951	\N	2026-08-07 05:50:24.91951	t	158	2026-08-07 09:39:44.079	852
9	2026-08-06	13	submitted	Iftikhar 	2026-08-06 12:15:37.982881	\N	2026-08-06 12:15:37.982881	t	159	2026-08-07 12:26:22.021	169950
3	2026-08-01	13	submitted	Iftikhar 	2026-08-05 15:13:49.011076	\N	2026-08-05 15:13:49.011076	t	160	2026-08-07 12:33:24.717	169808
14	2026-07-31	14	submitted	Hsn	2026-08-07 14:04:45.734997	Hsn	2026-08-07 14:05:12.041	t	164	2026-08-07 14:14:03.798	August 26 >----> Opening
13	2026-07-31	15	submitted	Hsn	2026-08-07 14:01:43.346427	Hsn	2026-08-07 14:03:58.678	t	165	2026-08-07 14:15:04.336	August-26 >---->  Opening
17	2026-08-05	14	submitted	Iftikhar 	2026-08-07 15:32:50.82745	Iftikhar 	2026-08-08 06:29:51.408	t	168	2026-08-08 06:47:23.411	47*15011
11	2026-07-31	13	submitted	Hsn	2026-08-07 13:32:38.03277	Hsn	2026-08-07 14:08:00.394	t	181	2026-08-08 07:39:21.867	August-26 >----> Opening
12	2026-07-31	16	submitted	Hsn	2026-08-07 13:43:04.390777	\N	2026-08-07 13:43:04.390777	t	182	2026-08-08 07:41:43.774	August-26 >---->Opening
15	2026-07-31	17	submitted	Hsn	2026-08-07 14:07:25.390882	\N	2026-08-07 14:07:25.390882	t	183	2026-08-08 07:44:51.579	August-26 >----> Opening
16	2026-07-31	20	submitted	Hsn	2026-08-07 14:11:11.661753	\N	2026-08-07 14:11:11.661753	t	184	2026-08-08 07:45:42.665	August-26 >----> Opening
18	2026-07-31	19	submitted	Hsn	2026-08-08 06:43:38.165898	\N	2026-08-08 06:43:38.165898	t	185	2026-08-08 07:46:23.931	August-26 >----> Opening
19	2026-08-10	16	submitted	Iftikhar 	2026-08-10 13:32:11.635391	\N	2026-08-10 13:32:11.635391	t	192	2026-08-11 06:12:17.383	0320
20	2026-08-01	16	submitted	Hsn	2026-08-11 07:04:47.713807	\N	2026-08-11 07:04:47.713807	t	194	2026-08-11 07:07:00.433	16237
21	2026-08-05	14	submitted	Iftikhar 	2026-08-11 07:39:31.106192	\N	2026-08-11 07:39:31.106192	t	196	2026-08-11 07:41:22.139	47*15011
22	2026-08-18	17	submitted	Iftikhar Ahmed	2026-08-19 11:31:08.766439	\N	2026-08-19 11:31:08.766439	f	\N	\N	1483
23	2026-08-18	17	submitted	Iftikhar Ahmed	2026-08-19 11:32:20.90415	\N	2026-08-19 11:32:20.90415	f	\N	\N	1484
24	2026-08-18	17	submitted	Iftikhar Ahmed	2026-08-19 11:33:54.607283	Iftikhar Ahmed	2026-08-19 11:35:52.385	f	\N	\N	1485
\.


--
-- Data for Name: yarn_type_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yarn_type_master (id, name, code, make_rate, hs_code) FROM stdin;
1	100% Cotton	CTN	\N	6002.9000
21	2-Fleece	2FL	3.00	6002.9000
20	3-Fleece	3FL	3.75	6002.9000
17	CVC (60/40)	CVC_60/40	\N	6002.9000
18	HG 	HG	\N	6002.9000
14	PC (52/48)	PC_52/48	\N	6002.9000
19	PC (60/40)	PC_60/40	\N	6002.9000
15	PC (65/35)	PC_65/35	\N	6002.9000
16	PC (75/25)	PC_75/25	\N	6002.9000
25	PC (80/20)	PC_80/20	\N	6002.9000
2	Polyester	POLYESTER	\N	6002.9000
24	RIB (1X1)	RIB_(1X1)	4.00	6002.9000
23	RIB (2X1)	RIB_(2X1)	4.00	6002.9000
22	Single Jersey	SJ	3.00	6002.9000
\.


--
-- Name: app_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.app_user_id_seq', 6, true);


--
-- Name: company_info_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.company_info_master_id_seq', 1, true);


--
-- Name: configuration_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.configuration_id_seq', 3, true);


--
-- Name: daily_delivery_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_delivery_id_seq', 42, true);


--
-- Name: daily_production_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_production_detail_id_seq', 1481, true);


--
-- Name: daily_production_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_production_header_id_seq', 203, true);


--
-- Name: department_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.department_master_id_seq', 4, true);


--
-- Name: fabric_type_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.fabric_type_master_id_seq', 16, true);


--
-- Name: factory_maintenance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.factory_maintenance_id_seq', 1, false);


--
-- Name: invoice_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invoice_id_seq', 254, true);


--
-- Name: invoice_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invoice_item_id_seq', 60, true);


--
-- Name: invoice_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invoice_payment_id_seq', 1, true);


--
-- Name: invoice_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invoice_transaction_id_seq', 1, false);


--
-- Name: job_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.job_master_id_seq', 24, true);


--
-- Name: location_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.location_master_id_seq', 18, true);


--
-- Name: machine_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.machine_history_id_seq', 10, true);


--
-- Name: machine_maintenance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.machine_maintenance_id_seq', 4, true);


--
-- Name: machine_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.machine_master_id_seq', 28, true);


--
-- Name: machine_operator_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.machine_operator_master_id_seq', 19, true);


--
-- Name: operator_advances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operator_advances_id_seq', 12, true);


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
-- Name: plausibility_baseline_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.plausibility_baseline_id_seq', 2136, true);


--
-- Name: plausibility_feedback_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.plausibility_feedback_id_seq', 19, true);


--
-- Name: role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.role_id_seq', 3, true);


--
-- Name: salary_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.salary_detail_id_seq', 6, true);


--
-- Name: salary_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.salary_header_id_seq', 1, true);


--
-- Name: transaction_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transaction_detail_id_seq', 770, true);


--
-- Name: transaction_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transaction_header_id_seq', 235, true);


--
-- Name: transaction_type_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transaction_type_master_id_seq', 8, true);


--
-- Name: uom_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.uom_master_id_seq', 12, true);


--
-- Name: yarn_brand_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_brand_master_id_seq', 20, true);


--
-- Name: yarn_count_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_count_master_id_seq', 52, true);


--
-- Name: yarn_receipt_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_receipt_detail_id_seq', 51, true);


--
-- Name: yarn_receipt_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_receipt_header_id_seq', 24, true);


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
-- Name: app_user app_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (id);


--
-- Name: app_user app_user_username_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_username_unique UNIQUE (username);


--
-- Name: company_info_master company_info_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_info_master
    ADD CONSTRAINT company_info_master_pkey PRIMARY KEY (id);


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
-- Name: role role_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_name_unique UNIQUE (name);


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

CREATE UNIQUE INDEX role_name_idx ON public.role USING btree (name);


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
-- Name: user_username_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_username_idx ON public.app_user USING btree (username);


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

\unrestrict Ay0XVDASSl5UgwyE6icWY9IqHNp1aSDYk2NaeS7m9zB0dzfCWAnlgXdpMu2bQjt

