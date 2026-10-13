# Analisis Soal 3 — Full-Stack & Audit Trail

**Nama** : Arfa Idraki Rori
**NIM**  : 12030124130110

## 1. Orkestrasi AI Tools

### a. Gemini Canvas — Generate UI HTML + Tailwind

**Pendekatan:** Pakai HTML + Tailwind CSS via CDN → 1 file yang bisa
langsung dibuka di browser tanpa perlu install Node.js atau build step.

**Prompt:** Lihat `frontend/prompts/gemini_canvas_prompt.md`.

**Hasil generate:**
- Form header (tanggal, no voucher, keterangan)
- Tabel dinamis dengan add/remove row
- Live balance indicator (update real-time)
- Tombol Submit auto-disable kalau tidak balance

**Modifikasi manual:**
- Pisahkan JavaScript ke `app.js`
- Tambahkan koneksi Supabase (`@supabase/supabase-js` via CDN)
- Fungsi `submitJournal()` yang insert ke DB

**Kenapa HTML+Tailwind (bukan Streamlit)?**
1. Tidak butuh Python environment → portabel, cukup buka `.html`
2. Bisa dideploy ke Vercel/Netlify dalam 1 klik
3. Lebih mendekati arsitektur produksi modern

### b. NotebookLM — Verifikasi PSAK 2

**Cara:** Upload PDF PSAK 2 + `index.html` + `app.js` → tanya checklist
kepatuhan pengakuan kas & setara kas.

**Hasil:** Lihat `psak_verification.md`.

**Ringkasan:**
- Pengakuan kas: ✅ sesuai (asas berpasangan debit-kredit)
- Setara kas: ⚠️ perlu pemisahan eksplisit di COA
- Audit trail: ✅ metadata lengkap

## 2. Audit Trail & Immutability

### a. Zero-Discrepancy di UI (frontend)

Tombol Submit disabled kecuali:
- Semua field header terisi
- ΣDebit = ΣKredit
- ΣDebit > 0
- Tidak ada baris "kosong" (debit = kredit = 0)

Ini **lapis pertama** pencegahan jurnal tidak balance.

### b. Immutability di Database (backend)

Dua trigger:
1. `trg_lock_posted_journal` — cegah UPDATE/DELETE header POSTED
2. `trg_lock_posted_lines` — cegah UPDATE/DELETE line dari header POSTED

Ini **lapis kedua**. Kalau frontend di-bypass (misal via API langsung),
database tetap menolak.

### c. Audit Field

| Field | Fungsi |
|-------|--------|
| `created_by` | User yang input |
| `created_at` | Waktu input |
| `posted_by` | User yang approve posting |
| `posted_at` | Waktu posting |
| `hash_checksum` | SHA-256 untuk verifikasi integritas |
| `reverses_id` | FK ke jurnal asli (kalau ini jurnal pembalik) |

### d. Hash Checksum

`hash_checksum = SHA256(header_id | trx_date | ref_no | desc | line_id | account_id | debit | credit)`

Kalau ada yang mengubah 1 karakter data, hash akan beda → terdeteksi.

## 3. Reversing Entry (Storno)

**Alur:**
1. Jurnal asli POSTED (header_id = 1) salah
2. Panggil `SELECT rpc_create_reversing_entry(1)`
3. Sistem bikin header baru (header_id = 2):
   - `reference_no` = "REV-JV-2026-0001"
   - `reverses_id` = 1
   - Debit & Kredit semua baris **ditukar**
4. Status jurnal asli → `REVERSED`
5. Kedua jurnal tetap ada → jejak audit terjaga

**Kenapa tidak boleh edit langsung?**
Karena mengubah jurnal POSTED = menghilangkan bukti audit.
Reversing entry = akuntansi standar (PSAK & IFRS sama).

## 4. Kesimpulan

| Aspek | Implementasi |
|-------|--------------|
| Frontend | HTML + Tailwind (Gemini Canvas) |
| Live balance | JavaScript real-time |
| Anti input salah | Tombol Submit auto-disable |
| Backend DB | Supabase + trigger + RPC |
| Immutability | Trigger BEFORE UPDATE/DELETE |
| Verifikasi PSAK | NotebookLM + PDF |
| Integritas data | SHA-256 hash checksum |
| Koreksi jurnal | RPC reversing entry |
