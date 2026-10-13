# LAPORAN UJIAN TENGAH SEMESTER
## Coding Akuntansi — FEB Universitas Diponegoro

---

**Nama**          : Arfa Idraki Rori  
**NIM**           : 12030124130110  
**Kelas**         : S1 Akuntansi Reguler  
**Mata Kuliah**   : Pemrograman / Coding  
**Dosen Pengampu**: Totok Dewayanto  
**Tanggal Ujian** : Senin, 19 Oktober 2026  

**🔗 Link Repositori GitHub**:  
https://github.com/arfarori23/UTS-Coding-Akuntansi-Arfa-12030124130110

---

## Daftar Isi

1. [Soal 1 — Desain Arsitektur Data & Normalisasi 3NF](#soal-1)
2. [Soal 2 — Otomasi Trigger & Concurrency](#soal-2)
3. [Soal 3 — Purwarupa Web & Orkestrasi AI](#soal-3)
4. [Kesimpulan](#kesimpulan)

---

<a name="soal-1"></a>
## SOAL 1 — Desain Arsitektur Data & Normalisasi 3NF

**Bobot**: 25% | **CPMK-1 / CPL-3, CPL-4**

### 1.1 Skema Relasional (ERD)

Skema terdiri dari 3 entitas:

| Entitas | Fungsi |
|---------|--------|
| `chart_of_accounts` | Master bagan akun (COA) |
| `journal_headers` | Kepala jurnal / voucher |
| `journal_lines` | Baris detail debit/kredit |

**Relasi:**
- `journal_headers` (1) ──< (N) `journal_lines`
- `chart_of_accounts` (1) ──< (N) `journal_lines`

Gambar ERD tersedia di `soal-1-erd-ddl/erd.png`.

### 1.2 DDL PostgreSQL

File: `soal-1-erd-ddl/schema.sql`

**Constraint yang diterapkan:**
- Primary Key di ketiga tabel
- Foreign Key dengan `ON DELETE RESTRICT` (cegah orphan journal)
- CHECK `debit >= 0` dan `credit >= 0` (cegah nilai negatif)
- CHECK `NOT (debit = 0 AND credit = 0)` (cegah baris kosong)
- CHECK `NOT (debit > 0 AND credit > 0)` (cegah 1 baris dua sisi)

**Uji coba:** Lihat `soal-1-erd-ddl/constraint_tests.sql` — 8 test (sukses & gagal) dengan screenshot di `docs/screenshots/soal-1/`.

### 1.3 Analisis Audit Trail & 3NF

**Mengapa Header–Line lebih andal:**

1. **Audit trail terpusat** — `status_posting` hanya di header → penguncian voucher cukup 1 operasi.
2. **Nomor bukti unik** — `reference_no` tidak berulang (di tabel flat, akan duplikat).
3. **Immutability selektif** — trigger kunci bisa diterapkan hanya di header.
4. **Reversing entry bersih** — storno = header baru yang merefer ke header asal.

**3NF:** Di model header–line, atribut non-kunci hanya bergantung pada PK tabelnya. Di tabel tunggal, `trx_date`, `reference_no`, `account_name` berulang di setiap baris → melanggar 2NF/3NF.

**Analisis lengkap**: lihat `soal-1-erd-ddl/ANALISIS.md`

---

<a name="soal-2"></a>
## SOAL 2 — Otomasi Trigger & Concurrency

**Bobot**: 40% | **CPMK-2 / CPL-3**

### 2.1 Trigger Otomatisasi Mutasi Stok

File: `soal-2-trigger/02_trigger_function.sql`

**Alur:**
1. Setiap INSERT di `inventory_transactions` → trigger `trg_inventory_update` aktif.
2. Fungsi `trg_update_stock_and_journal()`:
   - `SELECT ... FOR UPDATE` untuk kunci baris item.
   - `PURCHASE` → stok naik.
   - `SALE` → cek stok dulu; kalau kurang → `RAISE EXCEPTION`.
   - `ADJUSTMENT` → koreksi plus/minus.
3. Kalau SALE melebihi stok → error **"Stok tidak cukup..."** → transaksi rollback.

**Uji coba:** 7 test case di `04_test_cases.sql` — screenshot di `docs/screenshots/soal-2/`.

### 2.2 Concurrency (Race Condition)

**Skenario:** Stok = 1, dua kasir jual bersamaan → tanpa proteksi = oversell.

**Solusi yang dipilih: Pessimistic Locking (`SELECT ... FOR UPDATE`)**

- Kasir A dapat lock → jual → commit → lock lepas.
- Kasir B nunggu → dapat lock → cek stok = 0 → trigger `RAISE EXCEPTION` → rollback.

**Alternatif:** `SERIALIZABLE` isolation → PostgreSQL deteksi konflik otomatis.

**Alasan pilih Pessimistic:** update single-row, deterministic, tanpa retry logic.

**Analisis lengkap**: lihat `soal-2-trigger/ANALISIS.md`

---

<a name="soal-3"></a>
## SOAL 3 — Purwarupa Web & Orkestrasi AI

**Bobot**: 35% | **CPMK-3 / CPL-3, CPL-4**

### 3.1a Gemini Canvas — UI Voucher Entri Kas Keluar

**Stack:** HTML + Tailwind CSS + JavaScript (vanilla)

**File:** `soal-3-fullstack/frontend/index.html` & `app.js`

**Prompt:** `soal-3-fullstack/frontend/prompts/gemini_canvas_prompt.md`

**Fitur UI:**
- Form header (tanggal, no. voucher, keterangan)
- Tabel dinamis (add/remove row)
- Live balance indicator real-time
- Tombol Submit auto-disable kalau tidak balance

### 3.1b NotebookLM — Verifikasi PSAK 2

**Proses:** Upload PDF PSAK 2 + kode aplikasi ke NotebookLM → tanya checklist kepatuhan.

**Hasil:** Lihat `soal-3-fullstack/psak_verification.md`

**Ringkasan:**
- Pengakuan kas: ✅ sesuai asas berpasangan debit-kredit
- Setara kas: ⚠️ perlu pemisahan eksplisit di COA (rekomendasi)
- Audit trail: ✅ metadata lengkap

### 3.2 Audit Trail & Immutability

**File:** `soal-3-fullstack/backend/audit_trail.sql` & `reversing_entry_rpc.sql`

**Mekanisme:**

1. **Immutability trigger** — `trg_lock_posted_journal` menolak UPDATE/DELETE header POSTED.
2. **Audit field** — `created_by`, `created_at`, `posted_by`, `posted_at`, `hash_checksum`.
3. **Hash checksum** — SHA-256 dari header + lines untuk verifikasi integritas.
4. **Reversing entry** — RPC `rpc_create_reversing_entry()` yang bikin jurnal pembalik (debit/kredit ditukar) tanpa mengubah jurnal asli.
5. **Bypass flag** — `app.allow_posted_update` untuk izinkan operasi storno internal.

**Uji coba:** Screenshot di `docs/screenshots/soal-3/` — immutability test, reversing entry, UI balance.

**Analisis lengkap**: lihat `soal-3-fullstack/ANALISIS.md`

---

<a name="kesimpulan"></a>
## KESIMPULAN

Melalui UTS ini, tiga pilar utama sistem akuntansi terkomputerisasi berhasil diimplementasikan:

1. **Integritas Data (Soal 1)** — Skema relasional 3NF dengan constraint ketat (PK, FK RESTRICT, CHECK) menjamin tidak ada jurnal tidak balance yang lolos.

2. **Otomasi & Pengendalian (Soal 2)** — Trigger database memastikan setiap mutasi persediaan langsung memutakhirkan saldo, dengan proteksi anti-oversell dan anti-race-condition.

3. **Kepatuhan & Audit (Soal 3)** — Purwarupa web dengan audit trail lengkap (immutability, hash checksum, reversing entry) sesuai standar PSAK & praktik audit modern.

**Prinsip kunci:** Validasi di level database (*defense in depth*) lebih andal daripada hanya mengandalkan validasi frontend.

---

## LAMPIRAN

### Struktur Repositori
Lihat `README.md` di root repo.

### Screenshot Bukti Uji
- `docs/screenshots/soal-1/` — Uji DDL & constraint
- `docs/screenshots/soal-2/` — Uji trigger persediaan
- `docs/screenshots/soal-3/` — Uji immutability, reversing, UI

### AI Tools Log
- **Gemini Canvas**: `soal-3-fullstack/frontend/prompts/gemini_canvas_prompt.md`
- **NotebookLM**: `soal-3-fullstack/psak_verification.md`
