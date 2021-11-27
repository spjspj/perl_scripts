@echo off
rem Running it
echo Creating a Bitcoin Wallet with a known mnemonic
rem https://raw.githubusercontent.com/libbitcoin/libbitcoin-explorer/master/img/wallet-commands.png
bx mnemonic-to-seed one two three four five six seven eight nine ten eleven twelve > my.seed

type my.seed | bx ec-new > myecprivate.key
type myecprivate.key | bx ec-to-public > myecpublic.key
type myecpublic.key | bx ec-to-address > mybitcoinaddress


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
type mybitcoinaddress | bx fetch-balance
type mybitcoinaddress | bx fetch-history

echo =============================
echo =============================
echo Testing one
bx fetch-balance 1JziqzXeBPyHPeAHrG4DCDW4ASXeGGF6p6
bx fetch-history 1JziqzXeBPyHPeAHrG4DCDW4ASXeGGF6p6
