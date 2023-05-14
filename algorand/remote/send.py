#===============================================================================
# Author: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: May 2023
# Description: Send Algos from one account to another
#===============================================================================

import argparse
from algosdk.v2client import algod
from algosdk import transaction, mnemonic, account

# Read arguments
parser = argparse.ArgumentParser('Send Algos from one account to another')
parser.add_argument('-d', '--algod_address', type=str, help='Algod address', default='http://localhost:8022')
parser.add_argument('-t', '--algod_token', type=str, help='Algod token', default='a' * 64)
parser.add_argument('-p', '--sender_mnemonic', type=str, help='Private mnemonic of the sender account', required=True)
parser.add_argument('-r', '--receiver', type=str, help='Receiver account address', required=True)
parser.add_argument('-a', '--amount', type=int, help='Amount of Algos to send', default=1000000) # 1 Algo
args = parser.parse_args()

# Get private and public keys from the mnemonic
private_key = mnemonic.to_private_key(args.sender_mnemonic)
public_key = account.address_from_private_key(private_key)

# Connect to the Algod client
algod_client = algod.AlgodClient(args.algod_token, args.algod_address)

# Get sender and receiver account information
sender_info = algod_client.account_info(public_key)
receiver_info = algod_client.account_info(args.receiver)
print("Sender account balance:   {} microAlgos".format(sender_info.get('amount')))
print("Receiver account balance: {} microAlgos".format(receiver_info.get('amount')))

# Send the transaction
params = algod_client.suggested_params()
unsigned_txn = transaction.PaymentTxn(public_key, params, args.receiver, args.amount)
signed_txn = unsigned_txn.sign(private_key)
txid = algod_client.send_transaction(signed_txn)
print("Transaction ID: {}".format(txid))

# Wait for the transaction to be confirmed
txn_result = transaction.wait_for_confirmation(algod_client, txid, 10)
print("Transaction information: {}".format(txn_result))

# Get sender and receiver account information
sender_info = algod_client.account_info(public_key)
receiver_info = algod_client.account_info(args.receiver)
print("Sender account balance:   {} microAlgos".format(sender_info.get('amount')))
print("Receiver account balance: {} microAlgos".format(receiver_info.get('amount')))
