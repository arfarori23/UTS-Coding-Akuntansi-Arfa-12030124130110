-- ============================================================
-- SOAL 3.2 — RPC: Reversing Entry (Storno)
-- Supabase RPC yang bisa dipanggil dari frontend untuk membuat
-- jurnal pembalik tanpa mengubah jurnal asli.
-- ============================================================

CREATE OR REPLACE FUNCTION rpc_create_reversing_entry(p_original_header_id INT)
RETURNS INT AS $$
DECLARE
    v_new_header_id INT;
    v_orig          RECORD;
BEGIN
    -- Ambil header asli
    SELECT * INTO v_orig
    FROM journal_headers
    WHERE header_id = p_original_header_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Header asli dengan id % tidak ditemukan',
              p_original_header_id;
    END IF;

    IF v_orig.status_posting <> 'POSTED' THEN
        RAISE EXCEPTION 'Hanya jurnal POSTED yang bisa dibalik. Status sekarang: %',
              v_orig.status_posting;
    END IF;

    -- Bikin header baru (jurnal pembalik)
    INSERT INTO journal_headers (
        trx_date, reference_no, description, status_posting, reverses_id
    )
    VALUES (
        CURRENT_DATE,
        'REV-' || v_orig.reference_no,
        'Reversing entry untuk ' || v_orig.reference_no,
        'POSTED',
        p_original_header_id
    )
    RETURNING header_id INTO v_new_header_id;

    -- Copy baris dengan debit & kredit DITUKAR
    INSERT INTO journal_lines (header_id, account_id, debit, credit)
    SELECT v_new_header_id, account_id, credit, debit
    FROM journal_lines
    WHERE header_id = p_original_header_id;

    -- Tandai jurnal asli sebagai REVERSED
    UPDATE journal_headers
    SET status_posting = 'REVERSED'
    WHERE header_id = p_original_header_id;

    RETURN v_new_header_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Contoh pemanggilan dari SQL Editor:
-- SELECT rpc_create_reversing_entry(1);
