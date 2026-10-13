-- ============================================================
-- SOAL 3.2 — Audit Trail & Immutability
-- Nama : Arfa Idraki Rori
-- NIM  : 12030124130110
-- ============================================================

-- Aktifkan pgcrypto untuk SHA-256
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------------------------------------
-- 1. Tambah kolom audit ke journal_headers
-- ------------------------------------------------------------
ALTER TABLE journal_headers
    ADD COLUMN IF NOT EXISTS created_by     VARCHAR(50) DEFAULT current_user,
    ADD COLUMN IF NOT EXISTS created_at     TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS posted_by      VARCHAR(50),
    ADD COLUMN IF NOT EXISTS posted_at      TIMESTAMP,
    ADD COLUMN IF NOT EXISTS hash_checksum  TEXT,
    ADD COLUMN IF NOT EXISTS reverses_id    INT REFERENCES journal_headers(header_id);

-- ------------------------------------------------------------
-- 2. Trigger: Kunci jurnal POSTED
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_lock_posted_journal()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.status_posting = 'POSTED' THEN
        RAISE EXCEPTION
            'Jurnal POSTED tidak boleh diubah (header_id=%). Gunakan reversing entry.',
            OLD.header_id;
    END IF;

    IF TG_OP = 'DELETE' AND OLD.status_posting = 'POSTED' THEN
        RAISE EXCEPTION
            'Jurnal POSTED tidak boleh dihapus (header_id=%). Gunakan reversing entry.',
            OLD.header_id;
    END IF;

    -- Set posted_by & posted_at otomatis saat DRAFT → POSTED
    IF TG_OP = 'UPDATE'
       AND OLD.status_posting = 'DRAFT'
       AND NEW.status_posting = 'POSTED' THEN
        NEW.posted_by := current_user;
        NEW.posted_at := CURRENT_TIMESTAMP;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_lock_posted_journal ON journal_headers;

CREATE TRIGGER trg_lock_posted_journal
BEFORE UPDATE OR DELETE ON journal_headers
FOR EACH ROW
EXECUTE FUNCTION fn_lock_posted_journal();

-- ------------------------------------------------------------
-- 3. Trigger: Kunci journal_lines kalau header POSTED
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_lock_posted_lines()
RETURNS TRIGGER AS $$
DECLARE
    v_status VARCHAR(10);
BEGIN
    SELECT status_posting INTO v_status
    FROM journal_headers
    WHERE header_id = COALESCE(NEW.header_id, OLD.header_id);

    IF v_status = 'POSTED' THEN
        RAISE EXCEPTION
            'Baris jurnal dari header POSTED tidak boleh diubah/dihapus (header_id=%).',
            COALESCE(NEW.header_id, OLD.header_id);
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_lock_posted_lines ON journal_lines;

CREATE TRIGGER trg_lock_posted_lines
BEFORE UPDATE OR DELETE ON journal_lines
FOR EACH ROW
EXECUTE FUNCTION fn_lock_posted_lines();

-- ------------------------------------------------------------
-- 4. Fungsi: Hitung hash SHA-256
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_generate_journal_hash(p_header_id INT)
RETURNS TEXT AS $$
DECLARE
    v_payload TEXT;
BEGIN
    SELECT string_agg(
        h.header_id || '|' || h.trx_date || '|' || h.reference_no || '|' ||
        COALESCE(h.description,'') || '|' ||
        l.line_id || '|' || l.account_id || '|' || l.debit || '|' || l.credit,
        E'\n' ORDER BY l.line_id
    )
    INTO v_payload
    FROM journal_headers h
    LEFT JOIN journal_lines l ON l.header_id = h.header_id
    WHERE h.header_id = p_header_id;

    RETURN encode(digest(v_payload, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------
-- 5. Trigger: Set hash_checksum otomatis saat POSTED
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_set_hash_on_post()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status_posting = 'POSTED' AND NEW.hash_checksum IS NULL THEN
        NEW.hash_checksum := fn_generate_journal_hash(NEW.header_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_hash_post ON journal_headers;

CREATE TRIGGER trg_set_hash_post
BEFORE UPDATE ON journal_headers
FOR EACH ROW
EXECUTE FUNCTION fn_set_hash_on_post();
