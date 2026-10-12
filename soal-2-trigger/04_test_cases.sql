-- ============================================================
-- SOAL 2 — Test Cases (Uji Coba Trigger)
-- ============================================================

-- ------------------------------------------------------------
-- Setup: bikin master barang
-- ------------------------------------------------------------
INSERT INTO inventory_items (item_id, item_name, stock_qty, unit_cost)
VALUES
('BRG001', 'Kertas A4 Rim',    0, 55000.00),
('BRG002', 'Pulpen Standard',  0, 3500.00),
('BRG003', 'Tinta Printer',    0, 85000.00);

-- ------------------------------------------------------------
-- TEST 1: PURCHASE (beli) → stok naik ✅ SUKSES
-- ------------------------------------------------------------
INSERT INTO inventory_transactions (item_id, trx_type, qty)
VALUES ('BRG001', 'PURCHASE', 10);

-- Cek hasil: stok BRG001 harus jadi 10
SELECT item_id, item_name, stock_qty
FROM inventory_items WHERE item_id = 'BRG001';

-- ------------------------------------------------------------
-- TEST 2: SALE normal → stok turun ✅ SUKSES
-- ------------------------------------------------------------
INSERT INTO inventory_transactions (item_id, trx_type, qty)
VALUES ('BRG001', 'SALE', 3);

-- Cek hasil: stok BRG001 harus jadi 7
SELECT item_id, stock_qty FROM inventory_items WHERE item_id = 'BRG001';

-- ------------------------------------------------------------
-- TEST 3: SALE melebihi stok → RAISE EXCEPTION ❌ HARUS GAGAL
-- ------------------------------------------------------------
INSERT INTO inventory_transactions (item_id, trx_type, qty)
VALUES ('BRG001', 'SALE', 100);

-- Expected: ERROR "Stok tidak cukup untuk item BRG001 (Kertas A4 Rim).
--           Stok tersedia: 7, diminta: 100"

-- ------------------------------------------------------------
-- TEST 4: ADJUSTMENT negatif (koreksi stok opname) ✅ SUKSES
-- ------------------------------------------------------------
INSERT INTO inventory_transactions (item_id, trx_type, qty)
VALUES ('BRG001', 'ADJUSTMENT', -2);

-- Cek: stok BRG001 harus jadi 5 (7 - 2)
SELECT item_id, stock_qty FROM inventory_items WHERE item_id = 'BRG001';

-- ------------------------------------------------------------
-- TEST 5: ADJUSTMENT yang membuat stok minus ❌ HARUS GAGAL
-- ------------------------------------------------------------
INSERT INTO inventory_transactions (item_id, trx_type, qty)
VALUES ('BRG001', 'ADJUSTMENT', -100);

-- Expected: ERROR "Adjustment menyebabkan stok minus..."

-- ------------------------------------------------------------
-- TEST 6: PURCHASE untuk item yang tidak ada ❌ HARUS GAGAL
-- ------------------------------------------------------------
INSERT INTO inventory_transactions (item_id, trx_type, qty)
VALUES ('BRG999', 'PURCHASE', 5);

-- Expected: ERROR foreign key / "Item dengan ID BRG999 tidak ditemukan"

-- ------------------------------------------------------------
-- TEST 7: Cek stok akhir semua barang
-- ------------------------------------------------------------
SELECT
    i.item_id,
    i.item_name,
    i.stock_qty,
    COUNT(t.trx_id) AS total_transaksi
FROM inventory_items i
LEFT JOIN inventory_transactions t ON t.item_id = i.item_id
GROUP BY i.item_id, i.item_name, i.stock_qty
ORDER BY i.item_id;

-- Expected output:
--   BRG001 | Kertas A4 Rim    | 5  | 4
--   BRG002 | Pulpen Standard  | 0  | 0
--   BRG003 | Tinta Printer    | 0  | 0
