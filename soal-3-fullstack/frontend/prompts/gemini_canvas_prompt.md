# Dokumentasi Prompt — Gemini Canvas

**Tools:** Gemini Canvas (gemini.google.com)
**Tujuan:** Generate formulir entri jurnal Voucher Kas Keluar
**Output:** 1 file `index.html` (HTML + Tailwind CSS + JavaScript)

---

## PROMPT 1 — Generate UI Utama

Buatkan saya satu file HTML lengkap (termasuk Tailwind CSS via CDN dan
JavaScript vanilla) untuk formulir "Voucher Entri Kas Keluar" dengan
spesifikasi:

### Header Form
- Judul "Voucher Entri Kas Keluar" di atas
- Grid 3 kolom: Tanggal (date input), Nomor Voucher (text), Keterangan (text)
- Semua field wajib, dengan label di atas input

### Tabel Dinamis (Journal Lines)
- Kolom: Kode Akun | Nama Akun | Debit | Kredit | Hapus
- Baris awal: 2 baris kosong
- Tombol "+ Tambah Baris" di bawah tabel
- Tombol "×" di tiap baris untuk hapus (nonaktif kalau hanya 1 baris)
- Input Debit & Kredit pakai format angka dengan pemisah ribuan
- Kalau user isi Debit, otomatis Kredit di baris itu dikosongkan (dan sebaliknya)

### Live Balance Indicator
- Di bawah tabel, tampilkan 3 kartu: Total Debit | Total Kredit | Selisih
- Warna hijau kalau balance, merah kalau tidak balance
- Badge besar: "✅ BALANCE" atau "❌ TIDAK BALANCE (Selisih: Rp X)"
- Update real-time setiap user ketik

### Tombol Submit
- Di bawah: tombol besar "POSTING VOUCHER"
- disabled (abu-abu, cursor not-allowed) kalau:
  - Tanggal / No Voucher / Keterangan kosong
  - Total Debit ≠ Total Kredit
  - Total Debit = 0
  - Ada baris yang Debit & Kredit dua-duanya 0
- enabled (biru) kalau semua validasi lolos

### Styling
- Pakai Tailwind CSS via CDN: https://cdn.tailwindcss.com
- Font: Inter (via Google Fonts)
- Background: gradient slate-100 ke slate-200
- Card utama: putih, rounded-xl, shadow-lg
- Warna aksen: indigo-600

### JavaScript
- Event listener di setiap input untuk recompute total
- Function `updateBalance()` yang dipanggil setiap input berubah
- Function `addRow()` dan `removeRow(btn)`
- Function `validateAndSubmit()` saat tombol diklik → console.log payload JSON

Berikan kode lengkap dalam 1 blok HTML. Sertakan komentar penjelas
di bagian JavaScript-nya.
