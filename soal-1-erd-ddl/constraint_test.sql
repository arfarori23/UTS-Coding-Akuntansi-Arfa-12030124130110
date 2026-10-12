-- ============================================================
-- Uji Constraint — jalankan satu blok per blok di SQL Editor
-- Blok ❌ memang sengaja dibuat gagal
-- ============================================================

-- ✅ HARUS SUKSES
INSERT INTO chart_of_accounts (account_code, account_name, normal_balance, report_class)
VALUES ('1-1300', 'Perlengkapan', 'DEBIT', 'ASSET');

-- ❌ HARUS GAGAL: normal_balance invalid
INSERT INTO chart_of_accounts (account_code, account_name, normal_balance, report_class)
VALUES ('1-1400', 'Peralatan', 'NEUTRAL', 'ASSET');

-- ❌ HARUS GAGAL: debit negatif
INSERT INTO journal_lines (header_id, account_id, debit, credit)
VALUES (1, 1, -100.00, 0);

-- ❌ HARUS GAGAL: debit & kredit nol
INSERT INTO journal_lines (header_id, account_id, debit, credit)
VALUES (1, 1, 0, 0);

-- ❌ HARUS GAGAL: FK header_id tidak ada
INSERT INTO journal_lines (header_id, account_id, debit, credit)
VALUES (9999, 1, 100.00, 0);

-- ❌ HARUS GAGAL: FK account_id tidak ada
INSERT INTO journal_lines (header_id, account_id, debit, credit)
VALUES (1, 9999, 100.00, 0);

-- ❌ HARUS GAGAL: hapus header yang masih dipakai line
DELETE FROM journal_headers WHERE header_id = 1;

-- ✅ HARUS SUKSES
INSERT INTO journal_lines (header_id, account_id, debit, credit)
VALUES (2, 6, 500000.00, 0);
