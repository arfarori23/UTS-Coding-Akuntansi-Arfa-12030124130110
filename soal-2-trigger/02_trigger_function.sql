-- ============================================================
-- SOAL 2.1 — Trigger Function: Otomatisasi Mutasi Stok
-- ============================================================

CREATE OR REPLACE FUNCTION trg_update_stock_and_journal()
RETURNS TRIGGER AS $$
DECLARE
    v_current_stock INT;
BEGIN
    -- LANGKAH 1: Kunci baris item untuk cegah race condition (jelas di 2.2)
    SELECT stock_qty INTO v_current_stock
    FROM inventory_items
    WHERE item_id = NEW.item_id
    FOR UPDATE;

    -- Kalau item tidak ditemukan → error jelas
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Item dengan ID % tidak ditemukan di master inventory_items',
              NEW.item_id;
    END IF;

    -- LANGKAH 2: Proses sesuai jenis transaksi
    IF NEW.trx_type = 'PURCHASE' THEN
        -- Beli → stok naik
        IF NEW.qty <= 0 THEN
            RAISE EXCEPTION 'PURCHASE harus memiliki qty > 0, tetapi diberi %',
                  NEW.qty;
        END IF;

        UPDATE inventory_items
        SET stock_qty = stock_qty + NEW.qty
        WHERE item_id = NEW.item_id;

    ELSIF NEW.trx_type = 'SALE' THEN
        -- Jual → cek stok dulu (anti-negative inventory prevention)
        IF NEW.qty <= 0 THEN
            RAISE EXCEPTION 'SALE harus memiliki qty > 0, tetapi diberi %',
                  NEW.qty;
        END IF;

        IF v_current_stock - NEW.qty < 0 THEN
            RAISE EXCEPTION 'Stok tidak cukup untuk item % (%) . Stok tersedia: %, diminta: %',
                  NEW.item_id, (SELECT item_name FROM inventory_items WHERE item_id = NEW.item_id),
                  v_current_stock, NEW.qty;
        END IF;

        UPDATE inventory_items
        SET stock_qty = stock_qty - NEW.qty
        WHERE item_id = NEW.item_id;

    ELSIF NEW.trx_type = 'ADJUSTMENT' THEN
        -- Adjustment → qty boleh positif atau negatif (koreksi stok opname)
        IF v_current_stock + NEW.qty < 0 THEN
            RAISE EXCEPTION 'Adjustment menyebabkan stok minus. Stok sekarang: %, penyesuaian: %',
                  v_current_stock, NEW.qty;
        END IF;

        UPDATE inventory_items
        SET stock_qty = stock_qty + NEW.qty
        WHERE item_id = NEW.item_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger yang memicu fungsi di atas setiap ada INSERT
CREATE TRIGGER trg_inventory_update
AFTER INSERT ON inventory_transactions
FOR EACH ROW
EXECUTE FUNCTION trg_update_stock_and_journal();
