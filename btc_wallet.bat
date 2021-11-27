@echo off
rem Running it
echo Creating a Bitcoin Wallet with a known mnemonic
rem https://raw.githubusercontent.com/libbitcoin/libbitcoin-explorer/master/img/wallet-commands.png
d:\D_Downloads\bitcoin\bx.exe mnemonic-to-seed one two three four five six seven eight nine ten eleven twelve > my.seed

type my.seed | d:\D_Downloads\bitcoin\bx.exe ec-new > myecprivate.key
type myecprivate.key | d:\D_Downloads\bitcoin\bx.exe ec-to-public > myecpublic.key
type myecpublic.key | d:\D_Downloads\bitcoin\bx.exe ec-to-address > mybitcoinaddress


echo =============================
echo my.seed
type my.seed
echo myecprivate.key
type myecprivate.key
echo myecpublic.key
type myecpublic.key
echo =============================
echo mybitcoinaddress
type mybitcoinaddress

echo =============================
echo =============================
echo Mine!
type mybitcoinaddress | d:\D_Downloads\bitcoin\bx.exe fetch-balance
type mybitcoinaddress | d:\D_Downloads\bitcoin\bx.exe fetch-history

echo =============================
echo =============================
echo Testing one
d:\D_Downloads\bitcoin\bx.exe fetch-balance 1JziqzXeBPyHPeAHrG4DCDW4ASXeGGF6p6
d:\D_Downloads\bitcoin\bx.exe fetch-history 1JziqzXeBPyHPeAHrG4DCDW4ASXeGGF6p6
