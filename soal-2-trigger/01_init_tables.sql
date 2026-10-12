-- ============================================================
-- SOAL 2 — Tabel Dasar Persediaan Perpetual
-- Nama : Arfa Idraki Rori
-- NIM  : 12030124130110
-- ============================================================

DROP TABLE IF EXISTS inventory_transactions CASCADE;
DROP TABLE IF EXISTS inventory_items CASCADE;

-- Tabel master barang
CREATE TABLE inventory_items (
    item_id    VARCHAR(10) PRIMARY KEY,
    item_name  VARCHAR(100) NOT NULL,
    stock_qty  INT NOT NULL DEFAULT 0 CHECK (stock_qty >= 0),
    unit_cost  NUMERIC(15, 2) NOT NULL CHECK (unit_cost >= 0)
);

-- Tabel riwayat transaksi
CREATE TABLE inventory_transactions (
    trx_id    SERIAL PRIMARY KEY,
    item_id   VARCHAR(10) NOT NULL REFERENCES inventory_items(item_id)
              ON DELETE RESTRICT ON UPDATE CASCADE,
    trx_type  VARCHAR(10) NOT NULL
              CHECK (trx_type IN ('PURCHASE','SALE','ADJUSTMENT')),
    qty       INT NOT NULL,  -- bisa negatif khusus ADJUSTMENT
    trx_date  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index bantu performa
CREATE INDEX idx_trx_item   ON inventory_transactions(item_id);
CREATE INDEX idx_trx_type   ON inventory_transactions(trx_type);
CREATE INDEX idx_trx_date   ON inventory_transactions(trx_date);
