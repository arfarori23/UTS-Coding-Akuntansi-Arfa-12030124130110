-- Data uji coba

INSERT INTO chart_of_accounts (account_code, account_name, normal_balance, report_class) VALUES
('1-1000', 'Kas',                      'DEBIT',  'ASSET'),
('1-1100', 'Piutang Usaha',            'DEBIT',  'ASSET'),
('1-1200', 'Persediaan Barang Dagang', 'DEBIT',  'ASSET'),
('2-1000', 'Utang Usaha',              'CREDIT', 'LIABILITY'),
('3-1000', 'Modal Pemilik',            'CREDIT', 'EQUITY'),
('4-1000', 'Pendapatan Penjualan',     'CREDIT', 'REVENUE'),
('5-1000', 'Harga Pokok Penjualan',    'DEBIT',  'EXPENSE');

-- Transaksi 1: Setoran modal awal
INSERT INTO journal_headers (trx_date, reference_no, description, status_posting)
VALUES ('2026-10-01', 'JV-2026-0001', 'Setoran modal awal', 'POSTED');

INSERT INTO journal_lines (header_id, account_id, debit, credit) VALUES
(1, 1, 50000000.00, 0),
(1, 5, 0,          50000000.00);

-- Transaksi 2: Pembelian persediaan kredit
INSERT INTO journal_headers (trx_date, reference_no, description, status_posting)
VALUES ('2026-10-05', 'JV-2026-0002', 'Pembelian persediaan kredit', 'POSTED');

INSERT INTO journal_lines (header_id, account_id, debit, credit) VALUES
(2, 3, 15000000.00, 0),
(2, 4, 0,          15000000.00);
