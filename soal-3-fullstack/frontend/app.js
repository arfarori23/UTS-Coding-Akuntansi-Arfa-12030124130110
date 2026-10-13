/**
 * Inisialisasi Supabase Client dari variabel global.
 * Mengambil konfigurasi dari window.SUPABASE_URL dan window.SUPABASE_ANON_KEY
 */
function getSupabaseClient() {
    const supabaseUrl = window.SUPABASE_URL || 'https://uktbejtidbqoifscchpy.supabase.co';
    const supabaseKey = window.SUPABASE_ANON_KEY || 'sb_publishable_Dmkgist7i5i6Sdp6GDa36Q_WEiGv54d';

    if (!window.supabase) {
        console.error("SDK Supabase belum dimuat. Pastikan CDN @supabase/supabase-js telah terpasang di HTML.");
        return null;
    }

    // Menggunakan instance global supabase yang sudah diinisialisasi atau membuat client baru
    if (!window._supabaseInstance) {
        window._supabaseInstance = window.supabase.createClient(supabaseUrl, supabaseKey);
    }
    return window._supabaseInstance;
}

/**
 * Event Listener saat DOM telah siap.
 * Mengisi tanggal default dan 2 baris awal jurnal.
 */
document.addEventListener('DOMContentLoaded', () => {
    const tanggalInput = document.getElementById('tanggal');
    if (tanggalInput) {
        const today = new Date().toISOString().split('T')[0];
        tanggalInput.value = today;
    }

    // Mengosongkan tbody & menambah 2 baris awal
    const tbody = document.getElementById('journal-lines');
    if (tbody) {
        tbody.innerHTML = '';
        addRow();
        addRow();
    }

    updateBalance();
});

/**
 * Memformat angka string menjadi format ribuan Indonesia (misal: 1000000 -> 1.000.000).
 * @param {string|number} value 
 * @returns {string}
 */
function formatThousands(value) {
    if (value === null || value === undefined || value === '') return '';
    const cleanNum = value.toString().replace(/\D/g, '');
    if (!cleanNum) return '';
    return parseInt(cleanNum, 10).toLocaleString('id-ID');
}

/**
 * Mengubah string angka terformat ribuan menjadi nilai numerik asli.
 * @param {string} formattedStr 
 * @returns {number}
 */
function parseFormattedNumber(formattedStr) {
    if (!formattedStr) return 0;
    const cleanNum = formattedStr.replace(/\D/g, '');
    return cleanNum ? parseInt(cleanNum, 10) : 0;
}

/**
 * Mengatur input debit/kredit:
 * 1. Menerapkan masker ribuan.
 * 2. Menjamin saling hapus (Mutual Exclusivity).
 * @param {HTMLInputElement} input 
 * @param {'debit'|'kredit'} type 
 */
function handleAmountInput(input, type) {
    const rawValue = input.value;
    const numericValue = parseFormattedNumber(rawValue);

    if (numericValue > 0) {
        input.value = formatThousands(numericValue);
    } else {
        input.value = '';
    }

    // Mutual Exclusivity: jika debit diisi, kosongkan kredit (dan sebaliknya)
    const row = input.closest('tr');
    if (row && numericValue > 0) {
        if (type === 'debit') {
            const kreditInput = row.querySelector('.input-kredit');
            if (kreditInput) kreditInput.value = '';
        } else if (type === 'kredit') {
            const debitInput = row.querySelector('.input-debit');
            if (debitInput) debitInput.value = '';
        }
    }

    updateBalance();
}

/**
 * Menambahkan baris baru ke tabel jurnal dinamis.
 */
function addRow() {
    const tbody = document.getElementById('journal-lines');
    if (!tbody) return;

    const row = document.createElement('tr');
    row.className = 'journal-row transition-colors hover:bg-slate-50/80';

    row.innerHTML = `
        <td class="py-2.5 px-4">
            <input type="text" placeholder="mis. 1101" class="kode-akun w-full px-2.5 py-1.5 border border-slate-300 rounded-md text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none" oninput="updateBalance()">
        </td>
        <td class="py-2.5 px-4">
            <input type="text" placeholder="mis. Kas Kecil" class="nama-akun w-full px-2.5 py-1.5 border border-slate-300 rounded-md text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none" oninput="updateBalance()">
        </td>
        <td class="py-2.5 px-4">
            <input type="text" inputmode="numeric" placeholder="0" class="input-debit w-full px-2.5 py-1.5 border border-slate-300 rounded-md text-sm text-right focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none" oninput="handleAmountInput(this, 'debit')">
        </td>
        <td class="py-2.5 px-4">
            <input type="text" inputmode="numeric" placeholder="0" class="input-kredit w-full px-2.5 py-1.5 border border-slate-300 rounded-md text-sm text-right focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none" oninput="handleAmountInput(this, 'kredit')">
        </td>
        <td class="py-2.5 px-3 text-center">
            <button type="button" onclick="removeRow(this)" class="btn-delete text-rose-500 hover:text-rose-700 hover:bg-rose-50 w-8 h-8 rounded-full inline-flex items-center justify-center font-bold text-lg disabled:opacity-30 disabled:cursor-not-allowed transition-colors" title="Hapus Baris">
                &times;
            </button>
        </td>
    `;

    tbody.appendChild(row);
    updateDeleteButtons();
    updateBalance();
}

/**
 * Menghapus baris terpilih dari tabel jurnal.
 * @param {HTMLElement} button 
 */
function removeRow(button) {
    const rows = document.querySelectorAll('.journal-row');
    if (rows.length > 1) {
        const tr = button.closest('tr');
        if (tr) tr.remove();
        updateDeleteButtons();
        updateBalance();
    }
}

/**
 * Memperbarui status tombol hapus baris.
 */
function updateDeleteButtons() {
    const deleteButtons = document.querySelectorAll('.btn-delete');
    const isSingleRow = deleteButtons.length <= 1;

    deleteButtons.forEach(btn => {
        btn.disabled = isSingleRow;
    });
}

/**
 * Kalkulasi total debit, kredit, selisih, serta validasi kelayakan posting voucher.
 */
function updateBalance() {
    let totalDebit = 0;
    let totalKredit = 0;
    let invalidRowFound = false;

    const rows = document.querySelectorAll('.journal-row');

    rows.forEach(row => {
        const debitVal = parseFormattedNumber(row.querySelector('.input-debit')?.value);
        const kreditVal = parseFormattedNumber(row.querySelector('.input-kredit')?.value);
        const kodeAkun = row.querySelector('.kode-akun')?.value.trim();
        const namaAkun = row.querySelector('.nama-akun')?.value.trim();

        totalDebit += debitVal;
        totalKredit += kreditVal;

        // Validasi: Baris tidak boleh kosong debit & kredit keduanya, atau nama/kode akun kosong
        if ((debitVal === 0 && kreditVal === 0) || !kodeAkun || !namaAkun) {
            invalidRowFound = true;
        }
    });

    const selisih = Math.abs(totalDebit - totalKredit);
    const isBalanced = (totalDebit === totalKredit) && totalDebit > 0;

    // Update Kartu Ringkasan Total
    const cardDebit = document.getElementById('card-total-debit');
    const cardKredit = document.getElementById('card-total-kredit');
    const cardSelisih = document.getElementById('card-selisih');
    const cardSelisihWrapper = document.getElementById('card-selisih-wrapper');
    const balanceBadge = document.getElementById('balance-badge');

    if (cardDebit) cardDebit.innerText = 'Rp ' + formatThousands(totalDebit);
    if (cardKredit) cardKredit.innerText = 'Rp ' + formatThousands(totalKredit);
    if (cardSelisih) cardSelisih.innerText = 'Rp ' + formatThousands(selisih);

    // Update Indicator Badge Balance
    if (balanceBadge) {
        if (isBalanced) {
            balanceBadge.className = "p-4 rounded-xl border text-center font-bold text-base transition-all duration-300 flex items-center justify-center gap-2 bg-emerald-50 border-emerald-200 text-emerald-800 shadow-sm";
            balanceBadge.innerHTML = '<span>✅ BALANCE</span>';

            if (cardSelisihWrapper) cardSelisihWrapper.className = "bg-emerald-50/50 border border-emerald-200 p-4 rounded-xl transition-colors";
            if (cardSelisih) cardSelisih.className = "text-lg font-bold text-emerald-700";
        } else {
            balanceBadge.className = "p-4 rounded-xl border text-center font-bold text-base transition-all duration-300 flex items-center justify-center gap-2 bg-rose-50 border-rose-200 text-rose-800 shadow-sm";
            balanceBadge.innerHTML = `<span>❌ TIDAK BALANCE (Selisih: Rp ${formatThousands(selisih)})</span>`;

            if (cardSelisihWrapper) cardSelisihWrapper.className = "bg-rose-50/50 border border-rose-200 p-4 rounded-xl transition-colors";
            if (cardSelisih) cardSelisih.className = "text-lg font-bold text-rose-700";
        }
    }

    // Validasi Header Form Input
    const tanggal = document.getElementById('tanggal')?.value.trim() || '';
    const noVoucher = document.getElementById('noVoucher')?.value.trim() || '';
    const keterangan = document.getElementById('keterangan')?.value.trim() || '';

    const isHeaderValid = tanggal !== '' && noVoucher !== '' && keterangan !== '';

    // Evaluasi Status Tombol Submit
    const btnSubmit = document.getElementById('btn-submit');
    const isValidForSubmit = isHeaderValid && isBalanced && !invalidRowFound && totalDebit > 0;

    if (btnSubmit) {
        btnSubmit.disabled = !isValidForSubmit;
        if (isValidForSubmit) {
            btnSubmit.className = "w-full sm:w-auto px-8 py-3 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-lg shadow-md hover:shadow-lg cursor-pointer transition-all duration-200 text-sm tracking-wide transform active:scale-95";
        } else {
            btnSubmit.className = "w-full sm:w-auto px-8 py-3 bg-slate-200 text-slate-400 font-semibold rounded-lg shadow-none cursor-not-allowed transition-all duration-200 text-sm tracking-wide";
        }
    }
}

/**
 * Menyiapkan payload data dan mengirim transaksi jurnal ke Supabase.
 * Meng-insert record ke 'journal_headers' (status DRAFT) dan 'journal_lines'.
 */
async function submitJournal() {
    const btnSubmit = document.getElementById('btn-submit');
    const originalBtnText = btnSubmit ? btnSubmit.innerText : 'POSTING VOUCHER';

    try {
        // Kumpulkan Data Header Form
        const tanggal = document.getElementById('tanggal').value;
        const noVoucher = document.getElementById('noVoucher').value;
        const keterangan = document.getElementById('keterangan').value;

        // Kumpulkan Baris Jurnal
        const lines = [];
        let totalDebit = 0;
        let totalKredit = 0;

        document.querySelectorAll('.journal-row').forEach(row => {
            const kodeAkun = row.querySelector('.kode-akun').value.trim();
            const namaAkun = row.querySelector('.nama-akun').value.trim();
            const debit = parseFormattedNumber(row.querySelector('.input-debit').value);
            const kredit = parseFormattedNumber(row.querySelector('.input-kredit').value);

            totalDebit += debit;
            totalKredit += kredit;

            lines.push({
                kode_akun: kodeAkun,
                nama_akun: namaAkun,
                debit: debit,
                kredit: kredit
            });
        });

        // Safe Check Tambahan
        if (totalDebit !== totalKredit || totalDebit === 0) {
            showNotification('error', 'Jurnal tidak seimbang atau total berjumlah nol!');
            return;
        }

        // Tampilkan indikator loading pada tombol
        if (btnSubmit) {
            btnSubmit.disabled = true;
            btnSubmit.innerText = "MENYIMPAN DATA...";
        }

        // Dapatkan instance Supabase Client
        const supabase = getSupabaseClient();
        if (!supabase) {
            throw new Error("Gagal menginisialisasi Supabase Client. Periksa variabel SUPABASE_URL dan SUPABASE_ANON_KEY.");
        }

        /* 
         * ==========================================
         * API CALL 1: Insert ke tabel journal_headers
         * ==========================================
         */
        const headerPayload = {
            tanggal: tanggal,
            nomor_voucher: noVoucher,
            keterangan: keterangan,
            total_debit: totalDebit,
            total_kredit: totalKredit,
            status: "DRAFT" // Status diawali DRAFT sesuai spesifikasi
        };

        const { data: headerData, error: headerError } = await supabase
            .from('journal_headers')
            .insert([headerPayload])
            .select(); // Mengambil data record yang baru di-insert (termasuk ID)

        if (headerError) {
            throw new Error(`[Header Error] ${headerError.message}`);
        }

        if (!headerData || headerData.length === 0) {
            throw new Error("Gagal menyimpan header jurnal (tidak ada data respons).");
        }

        // Ambil Primary Key ID dari header yang baru dibuat
        const insertedHeaderId = headerData[0].id;

        /* 
         * ==========================================
         * API CALL 2: Insert ke tabel journal_lines
         * ==========================================
         */
        const linesPayload = lines.map(line => ({
            header_id: insertedHeaderId, // Foreign key ke journal_headers
            kode_akun: line.kode_akun,
            nama_akun: line.nama_akun,
            debit: line.debit,
            kredit: line.kredit
        }));

        const { error: linesError } = await supabase
            .from('journal_lines')
            .insert(linesPayload);

        if (linesError) {
            throw new Error(`[Lines Error] ${linesError.message}`);
        }

        // Tampilkan Payload JSON di Konsol untuk debugging
        console.log("=== SUPABASE POSTING SUCCESS ===");
        console.log("Header Result:", headerData[0]);
        console.log("Lines Inserted:", linesPayload);

        // Jika sukses → Tampilkan notifikasi & Reset form
        showNotification('success', 'Voucher berhasil disimpan ke Supabase dengan status DRAFT!', JSON.stringify({ header: headerData[0], lines: linesPayload }, null, 2));
        resetForm();

    } catch (err) {
        console.error("Gagal mengirim transaksi jurnal:", err);
        showNotification('error', `Gagal menyimpan jurnal ke Supabase: ${err.message}`);
    } finally {
        if (btnSubmit) {
            btnSubmit.innerText = originalBtnText;
            updateBalance(); // Re-evaluasi tombol submit
        }
    }
}

/**
 * Wrapper function untuk dipanggil oleh tombol click HTML
 */
function validateAndSubmit() {
    submitJournal();
}

/**
 * Menampilkan Modal Dialog Feedback (Menggantikan alert biasa)
 * @param {'success'|'error'} type 
 * @param {string} message 
 * @param {string} [jsonPreview] 
 */
function showNotification(type, message, jsonPreview = '') {
    const modal = document.getElementById('modal-success');
    const previewContainer = document.getElementById('json-preview');
    const modalTitle = modal ? modal.querySelector('.text-emerald-600, .text-rose-600') : null;

    if (!modal) return;

    if (type === 'success') {
        if (modalTitle) {
            modalTitle.className = "flex items-center gap-2 text-emerald-600 font-bold text-lg";
            modalTitle.innerHTML = `
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                </svg>
                Berhasil Diposting!
            `;
        }
    } else {
        if (modalTitle) {
            modalTitle.className = "flex items-center gap-2 text-rose-600 font-bold text-lg";
            modalTitle.innerHTML = `
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                Gagal Memproses Data
            `;
        }
    }

    const messageText = modal.querySelector('p');
    if (messageText) messageText.innerText = message;

    if (previewContainer) {
        if (jsonPreview) {
            previewContainer.innerText = jsonPreview;
            previewContainer.parentElement.classList.remove('hidden');
        } else {
            previewContainer.parentElement.classList.add('hidden');
        }
    }

    modal.classList.remove('hidden');
    modal.classList.add('flex');
}

/**
 * Menutup modal notifikasi.
 */
function closeModal() {
    const modal = document.getElementById('modal-success');
    if (modal) {
        modal.classList.add('hidden');
        modal.classList.remove('flex');
    }
}

/**
 * Membersihkan seluruh isi form ke kondisi awal.
 */
function resetForm() {
    const noVoucher = document.getElementById('noVoucher');
    const keterangan = document.getElementById('keterangan');

    if (noVoucher) noVoucher.value = '';
    if (keterangan) keterangan.value = '';

    const tbody = document.getElementById('journal-lines');
    if (tbody) {
        tbody.innerHTML = '';
        addRow();
        addRow();
    }

    updateBalance();
}
