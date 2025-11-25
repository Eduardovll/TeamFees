--
-- PostgreSQL database dump
--

\restrict YsbwomGne95gylI29V1GgD3L3Rt5c6Fko90eZ2N2Mgz28lqKpVcQgXe7sLKrDEy

-- Dumped from database version 18.0
-- Dumped by pg_dump version 18.0

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: member; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member (
    id integer NOT NULL,
    full_name character varying(150) NOT NULL,
    phone_whatsapp character varying(30),
    email character varying(150),
    cpf character varying(14),
    is_active boolean DEFAULT true,
    role character varying(20) DEFAULT 'member'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    password_hash character varying(200)
);


--
-- Name: member_fee; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member_fee (
    id integer NOT NULL,
    member_id integer NOT NULL,
    cycle_id integer NOT NULL,
    amount_cents integer NOT NULL,
    status character varying(20) DEFAULT 'OPEN'::character varying NOT NULL,
    pix_txid character varying(100),
    pix_provider_id character varying(100),
    pix_qr_code text,
    due_date date NOT NULL,
    paid_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: member_fee_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_fee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_fee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.member_fee_id_seq OWNED BY public.member_fee.id;


--
-- Name: member_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.member_id_seq OWNED BY public.member.id;


--
-- Name: member_invitation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member_invitation (
    id integer NOT NULL,
    member_id integer NOT NULL,
    token character varying(100) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    activated_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: member_invitation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_invitation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_invitation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.member_invitation_id_seq OWNED BY public.member_invitation.id;


--
-- Name: payment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment (
    id integer NOT NULL,
    member_fee_id integer NOT NULL,
    amount_cents integer NOT NULL,
    method character varying(20) NOT NULL,
    transaction_id character varying(100),
    paid_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: payment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_id_seq OWNED BY public.payment.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    full_name character varying(150) NOT NULL,
    email character varying(150) NOT NULL,
    password_hash character varying(200) NOT NULL,
    role character varying(20) DEFAULT 'member'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
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
-- Name: vw_payment_detailed; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_payment_detailed AS
 SELECT p.id AS payment_id,
    p.member_fee_id,
    m.id AS member_id,
    m.full_name AS member_name,
    m.email AS member_email,
    f.cycle_id,
    f.amount_cents AS fee_amount_cents,
    p.amount_cents AS paid_amount_cents,
    p.method,
    p.created_at,
    f.status AS fee_status,
    f.due_date,
    f.paid_at
   FROM ((public.payment p
     JOIN public.member_fee f ON ((f.id = p.member_fee_id)))
     JOIN public.member m ON ((m.id = f.member_id)))
  ORDER BY p.created_at DESC;


--
-- Name: member id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member ALTER COLUMN id SET DEFAULT nextval('public.member_id_seq'::regclass);


--
-- Name: member_fee id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_fee ALTER COLUMN id SET DEFAULT nextval('public.member_fee_id_seq'::regclass);


--
-- Name: member_invitation id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_invitation ALTER COLUMN id SET DEFAULT nextval('public.member_invitation_id_seq'::regclass);


--
-- Name: payment id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment ALTER COLUMN id SET DEFAULT nextval('public.payment_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: member_fee member_fee_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_fee
    ADD CONSTRAINT member_fee_pkey PRIMARY KEY (id);


--
-- Name: member_invitation member_invitation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_invitation
    ADD CONSTRAINT member_invitation_pkey PRIMARY KEY (id);


--
-- Name: member_invitation member_invitation_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_invitation
    ADD CONSTRAINT member_invitation_token_key UNIQUE (token);


--
-- Name: member member_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_pkey PRIMARY KEY (id);


--
-- Name: payment payment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_member_fee_txid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_member_fee_txid ON public.member_fee USING btree (pix_txid);


--
-- Name: idx_member_invitation_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_member_invitation_member_id ON public.member_invitation USING btree (member_id);


--
-- Name: idx_member_invitation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_member_invitation_token ON public.member_invitation USING btree (token);


--
-- Name: idx_payment_fee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_fee_id ON public.payment USING btree (member_fee_id);


--
-- Name: member_invitation fk_member; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_invitation
    ADD CONSTRAINT fk_member FOREIGN KEY (member_id) REFERENCES public.member(id);


--
-- Name: member_fee member_fee_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_fee
    ADD CONSTRAINT member_fee_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.member(id) ON DELETE CASCADE;


--
-- Name: member_invitation member_invitation_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_invitation
    ADD CONSTRAINT member_invitation_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.member(id) ON DELETE CASCADE;


--
-- Name: payment payment_member_fee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_member_fee_id_fkey FOREIGN KEY (member_fee_id) REFERENCES public.member_fee(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict YsbwomGne95gylI29V1GgD3L3Rt5c6Fko90eZ2N2Mgz28lqKpVcQgXe7sLKrDEy

