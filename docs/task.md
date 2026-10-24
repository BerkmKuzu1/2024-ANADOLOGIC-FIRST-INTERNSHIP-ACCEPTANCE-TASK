# AnadoLogic 2024 Staj Görevi

Orijinal PDF: [berk_muammer_kuzu_task.pdf](berk_muammer_kuzu_task.pdf)

Bir sisteme UART üzerinden 16-bit 2 sayı üzerinde matematiksel işlem yapılması
gereken ve sonucun cevap olarak dönüldüğü bir modül tasarlanacaktır.

## Gelen mesaj

UART mesaj yapısı aşağıdaki gibidir:

| Alan | Boyut |
| --- | --- |
| Header (`0xBACD`) | 2 byte |
| Num1 (2's complement) | 2 byte |
| Num2 (2's complement) | 2 byte |
| Opcode | 1 byte |
| Checksum | 1 byte |

Gelen mesaj = [Header – Num1 – Num2 – Opcode – Checksum]

Checksum hesabı, checksum dahil bütün paketin toplamının mod256'sı (toplamın son
8-biti) 0x00 olmalıdır.

Opcode: 0 ise Num1 + Num2 yapılır, 1 ise Num1 – Num2 yapılır.

Örnek gelen mesaj: `0xBACD001000200049`

| Değer | Anlamı |
| --- | --- |
| `0xBACD` | header |
| `0x0010` | Num1 (decimal 16) |
| `0x0020` | Num2 (decimal 32) |
| `0x00` | opcode |
| `0x49` | checksum |

Hepsini topla 0x200 yapar.

## Cevap mesajı

Bu mesaj geldiğinde istenilen işlem yapılıp sonuç aşağıdaki formatta cevap olarak
dönülecektir:

| Alan | Boyut |
| --- | --- |
| Header (`0xABCD`) | 2 byte |
| Result | 2 byte |
| Checksum | 1 byte |

- `0xBACD001000200049` mesajına cevap aşağıdaki gibi olmalıdır: `0xABCD003058`
- `0xBACD001000200148` mesajına cevap aşağıdaki gibi olmalıdır: `0xABCDFFF099`

## Modül giriş çıkışları

**Inputs**

- `clk`
- `rst` (active-high synchronous reset)
- `rx_i` (uart receiver port)

**Outputs**

- `tx_o` (uart transmitter port)

## Tasks

- Önce bu sistem VHDL dilinde tasarlanacak. Birden fazla dosya kullanılabilir,
  top modül ismi `top.vhd` olacak.
- Sistem VHDL dili kullanılarak testbench kodu yazılıp simüle edilecek. En az
  1 adet toplama, 1 adet çıkarma ve 1 adet hatalı checksum mesajı gönderilerek
  test edilecek. Vivado sim ya da Modelsim kullanılabilir.
- Yazılan kodlar ve dokümantasyon public bir GitHub repoya oluşturulup oraya
  aktarılacak. Dokümantasyon `readme.md` dosyası olarak markup dilinde yapılacak.

## Süre

1 hafta – Deadline 01.12.2024 23:59
