# Analisis Soal 2 — Trigger Persediaan & Concurrency

**Nama** : Arfa Idraki Rori
**NIM**  : 12030124130110

## 1. Otomatisasi Mutasi via Trigger

### a. Mengapa Trigger? Bukan Aplikasi Backend?

Kalau update stok dilakukan di kode aplikasi (Node/Python), muncul celah:
- Kalau ada staf pakai SQL langsung (mis. via Supabase dashboard), trigger tidak jalan.
- Kalau aplikasi crash di tengah jalan, stok bisa tidak ter-update.

Trigger di level **database** menjamin:
1. **Atomic** — update stok dan pencatatan transaksi terjadi dalam satu transaksi.
2. **Konsisten** — semua jalur (API, dashboard, script) otomatis kena aturan.
3. **Auditable** — constraint terakhir sebelum data tersimpan.

### b. Mengapa `AFTER INSERT` bukan `BEFORE INSERT`?

- `AFTER INSERT`: baris transaksi **sudah** masuk dulu, baru update stok.
  Kalau update gagal → seluruh transaksi (termasuk baris transaksi) **rollback**.
- `BEFORE INSERT`: lebih rumit, karena `NEW.trx_id` belum ada.

Untuk kasus ini, `AFTER INSERT` + `RAISE EXCEPTION` = kombinasi paling aman.

### c. Mengapa Ada `CHECK (stock_qty >= 0)` di Tabel?

**Defense in depth** — dua lapis:
- Lapis 1: Trigger cek stok sebelum update → pesan error jelas ke user.
- Lapis 2: CHECK constraint di tabel → kalau ada bug di trigger, DB tetap tidak
  bisa menyimpan nilai minus.

## 2. Penanganan Concurrency (Race Condition)

### a. Skenario Race Condition
