-- ============================================================
-- SOAL 2.2 — Penanganan Concurrency (Race Condition)
-- ============================================================
--
-- SKENARIO:
-- Stok barang "BRG001" = 1 unit.
-- Kasir A dan Kasir B bersamaan klik "Jual 1 unit" pada detik yang sama.
-- Tanpa proteksi → keduanya lolos cek → stok jadi -1 (OVERSELING).
--
-- SOLUSI 1 — PESSIMISTIC LOCKING (SELECT ... FOR UPDATE)
-- --------------------------------------------------------
-- Kunci baris item sebelum cek stok. Kasir kedua akan MENUNGGU
-- sampai kasir pertama commit/rollback.

BEGIN;
    -- Kunci baris: kasir lain otomatis nunggu di sini
    SELECT stock_qty FROM inventory_items
    WHERE item_id = 'BRG001'
    FOR UPDATE;

    -- Setelah lock didapat, cek stok dengan nilai paling fresh
    -- (trigger di 02_trigger_function.sql sudah handle cek & update,
    --  jadi cukup INSERT saja di sini)
    INSERT INTO inventory_transactions (item_id, trx_type, qty)
    VALUES ('BRG001', 'SALE', 1);
COMMIT;

-- Hasil:
--   Kasir A → dapat lock, stok 1 → jual 1 → stok 0 → commit
--   Kasir B → nunggu, dapat lock, stok 0 → INSERT memicu RAISE EXCEPTION
--             "Stok tidak cukup..." → rollback
--
-- SOLUSI 2 — SERIALIZABLE ISOLATION (alternatif)
-- --------------------------------------------------------
-- Tidak pakai lock manual, tapi set level isolasi paling ketat.
-- PostgreSQL otomatis deteksi bentrok dan rollback salah satu.
-- Cocok kalau tidak mau mikirin locking manual.

BEGIN ISOLATION LEVEL SERIALIZABLE;
    INSERT INTO inventory_transactions (item_id, trx_type, qty)
    VALUES ('BRG001', 'SALE', 1);
COMMIT;
-- Kalau bentrok → ERROR: could not serialize access due to concurrent update
--             → aplikasi harus RETRY

-- REKOMENDASI UNTUK UTS INI:
-- Gunakan SOLUSI 1 (SELECT ... FOR UPDATE) karena:
--   1. Lebih sederhana, tidak perlu retry logic.
--   2. Lebih predictable untuk kasus single-row update seperti ini.
--   3. Sudah otomatis diimplementasikan di dalam fungsi trigger kita
--      (baris "SELECT ... FOR UPDATE" di 02_trigger_function.sql).
