-- ============================================================
-- SOAL 1.2 — DDL PostgreSQL: Modul General Ledger
-- Nama : <ARFA IDRAKI RORI>
-- NIM  : <12030124130110>
-- ============================================================

DROP TABLE IF EXISTS journal_lines CASCADE;
DROP TABLE IF EXISTS journal_headers CASCADE;
DROP TABLE IF EXISTS chart_of_accounts CASCADE;

-- ------------------------------------------------------------
-- Tabel 1: chart_of_accounts
-- ------------------------------------------------------------
CREATE TABLE chart_of_accounts (
    account_id      SERIAL       PRIMARY KEY,
    account_code    VARCHAR(20)  NOT NULL UNIQUE,
    account_name    VARCHAR(100) NOT NULL,
    normal_balance  VARCHAR(6)   NOT NULL
                    CHECK (normal_balance IN ('DEBIT','CREDIT')),
    report_class    VARCHAR(20)  NOT NULL
                    CHECK (report_class IN ('ASSET','LIABILITY','EQUITY','REVENUE','EXPENSE')),
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- Tabel 2: journal_headers
-- ------------------------------------------------------------
CREATE TABLE journal_headers (
    header_id       SERIAL       PRIMARY KEY,
    trx_date        DATE         NOT NULL,
    reference_no    VARCHAR(50)  NOT NULL UNIQUE,
    description     TEXT,
    status_posting  VARCHAR(10)  NOT NULL DEFAULT 'DRAFT'
                    CHECK (status_posting IN ('DRAFT','POSTED','REVERSED')),
    created_by      VARCHAR(50)  NOT NULL DEFAULT current_user,
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- Tabel 3: journal_lines
-- ------------------------------------------------------------
CREATE TABLE journal_lines (
    line_id     SERIAL        PRIMARY KEY,
    header_id   INT           NOT NULL,
    account_id  INT           NOT NULL,
    debit       NUMERIC(15,2) NOT NULL DEFAULT 0,
    credit      NUMERIC(15,2) NOT NULL DEFAULT 0,

    CONSTRAINT fk_lines_header
        FOREIGN KEY (header_id) REFERENCES journal_headers(header_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_lines_account
        FOREIGN KEY (account_id) REFERENCES chart_of_accounts(account_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT chk_debit_non_negative  CHECK (debit  >= 0),
    CONSTRAINT chk_credit_non_negative CHECK (credit >= 0),
    CONSTRAINT chk_not_both_zero       CHECK (NOT (debit = 0 AND credit = 0)),
    CONSTRAINT chk_not_both_filled     CHECK (NOT (debit > 0 AND credit > 0))
);

CREATE INDEX idx_lines_header   ON journal_lines(header_id);
CREATE INDEX idx_lines_account  ON journal_lines(account_id);
CREATE INDEX idx_headers_date   ON journal_headers(trx_date);
CREATE INDEX idx_headers_status ON journal_headers(status_posting);