package main

// ===============================================================================
// Source: https://github.com/Blockchain-Benchmarking/minion/blob/cleanup/script/remote/linux/apt/install-algorand
// ===============================================================================

import (
	"bufio"
	"context"
	"crypto/sha512"
	"database/sql"
	"encoding/base32"
	"fmt"
	"os"
	"strconv"

	"github.com/algorand/go-algorand-sdk/mnemonic"
	"github.com/algorand/go-algorand/logging"
	"github.com/algorand/go-algorand/protocol"
	"github.com/algorand/go-algorand/util/db"
	"github.com/algorand/msgp/msgp"
)

/* Classical signatures */
type ed25519PublicKey [32]byte
type ed25519PrivateKey [64]byte

// PrivateKey is an exported ed25519PrivateKey
type PrivateKey ed25519PrivateKey

// PublicKey is an exported ed25519PublicKey
type PublicKey ed25519PublicKey

// UnmarshalMsg implements msgp.Unmarshaler
func (z *PublicKey) UnmarshalMsg(bts []byte) (o []byte, err error) {
	bts, err = msgp.ReadExactBytes(bts, (*z)[:])
	if err != nil {
		err = msgp.WrapError(err)
		return
	}
	o = bts
	return
}

func (*PublicKey) CanUnmarshalMsg(z interface{}) bool {
	_, ok := (z).(*PublicKey)
	return ok
}

// A SignatureVerifier is used to identify the holder of SignatureSecrets
// and verify the authenticity of Signatures.
type SignatureVerifier = PublicKey

// UnmarshalMsg implements msgp.Unmarshaler
func (z *SignatureSecrets) UnmarshalMsg(bts []byte) (o []byte, err error) {
	var field []byte
	_ = field
	var zb0002 int
	var zb0003 bool
	zb0002, zb0003, bts, err = msgp.ReadMapHeaderBytes(bts)
	if _, ok := err.(msgp.TypeError); ok {
		zb0002, _, bts, err = msgp.ReadArrayHeaderBytes(bts)
		if err != nil {
			err = msgp.WrapError(err)
			return
		}
		if zb0002 > 0 {
			zb0002--
			bts, err = (*z).SignatureVerifier.UnmarshalMsg(bts)
			if err != nil {
				err = msgp.WrapError(err, "struct-from-array", "SignatureVerifier")
				return
			}
		}
		if zb0002 > 0 {
			zb0002--
			bts, err = msgp.ReadExactBytes(bts, ((*z).SK)[:])
			if err != nil {
				err = msgp.WrapError(err, "struct-from-array", "SK")
				return
			}
		}
		if zb0002 > 0 {
			err = msgp.ErrTooManyArrayFields(zb0002)
			err = msgp.WrapError(err, "struct-from-array")
			return
		}
	} else {
		if err != nil {
			err = msgp.WrapError(err)
			return
		}
		if zb0003 {
			(*z) = SignatureSecrets{}
		}
		for zb0002 > 0 {
			zb0002--
			field, bts, err = msgp.ReadMapKeyZC(bts)
			if err != nil {
				err = msgp.WrapError(err)
				return
			}
			switch string(field) {
			case "SignatureVerifier":
				bts, err = (*z).SignatureVerifier.UnmarshalMsg(bts)
				if err != nil {
					err = msgp.WrapError(err, "SignatureVerifier")
					return
				}
			case "SK":
				bts, err = msgp.ReadExactBytes(bts, ((*z).SK)[:])
				if err != nil {
					err = msgp.WrapError(err, "SK")
					return
				}
			default:
				err = msgp.ErrNoField(string(field))
				err = msgp.WrapError(err)
				return
			}
		}
	}
	o = bts
	return
}

func (*SignatureSecrets) CanUnmarshalMsg(z interface{}) bool {
	_, ok := (z).(*SignatureSecrets)
	return ok
}

// SignatureSecrets are used by an entity to produce unforgeable signatures over
// a message.
type SignatureSecrets struct {
	SignatureVerifier
	SK ed25519PrivateKey
}

// A Root encapsulates a set of secrets which controls some store of money.
//
// A Root is authorized to spend money and create Participations
// for which this account is the parent.
//
// It handles persistence and secure deletion of secrets.
type Root struct {
	secrets *SignatureSecrets

	store db.Accessor
}

// RestoreRoot restores a Root from a database handle.
func RestoreRoot(store db.Accessor) (acc Root, err error) {
	var raw []byte

	err = store.Atomic(func(ctx context.Context, tx *sql.Tx) error {
		var nrows int
		row := tx.QueryRow("select count(*) from RootAccount")
		err := row.Scan(&nrows)
		if err != nil {
			return fmt.Errorf("RestoreRoot: could not query storage: %v", err)
		}
		if nrows != 1 {
			logging.Base().Infof("RestoreRoot: state not found (n = %v)", nrows)
		}

		row = tx.QueryRow("select data from RootAccount")
		err = row.Scan(&raw)
		if err != nil {
			return fmt.Errorf("RestoreRoot: could not read account raw data: %v", err)
		}

		return nil
	})

	if err != nil {
		return
	}

	acc.secrets = &SignatureSecrets{}
	err = protocol.Decode(raw, acc.secrets)
	if err != nil {
		err = fmt.Errorf("RestoreRoot: error decoding account: %v", err)
		return
	}

	acc.store = store
	return
}

// Secrets returns the signing secrets associated with the Root account.
func (root Root) Secrets() *SignatureSecrets {
	return root.secrets
}

// Address returns the address associated with the Root account.
func (root Root) Address() Address {
	return Address(root.secrets.SignatureVerifier)
}

// DigestSize is the number of bytes in the preferred hash Digest used here.
const DigestSize = sha512.Size256

// Digest represents a 32-byte value holding the 256-bit Hash digest.
type Digest [DigestSize]byte

// Hash computes the SHASum512_256 hash of an array of bytes
func Hash(data []byte) Digest {
	return sha512.Sum512_256(data)
}

type (
	// Address is a unique identifier corresponding to ownership of money
	Address Digest
)

const (
	checksumLength = 4
)

var base32Encoder = base32.StdEncoding.WithPadding(base32.NoPadding)

// String returns a string representation of Address
func (addr Address) String() string {
	addrWithChecksum := make([]byte, DigestSize+checksumLength)
	copy(addrWithChecksum[:DigestSize], addr[:])
	// calling addr.GetChecksum() here takes 20ns more than just rolling it out, so we'll just repeat that code.
	shortAddressHash := Hash(addr[:])
	copy(addrWithChecksum[DigestSize:], shortAddressHash[len(shortAddressHash)-checksumLength:])
	return base32Encoder.EncodeToString(addrWithChecksum)
}

type WalletResult struct {
	Address  string
	Mnemonic string
	Error    error
}

func main() {
	netroot := os.Args[1]
	nodenum, err := strconv.ParseUint(os.Args[2], 10, 64)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	chainconfig := os.Args[3]

	file, err := os.Create(chainconfig)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer file.Close()

	writer := bufio.NewWriter(file)
	defer writer.Flush()

	sem := make(chan *WalletResult, nodenum)
	for i := uint64(0); i < nodenum; i++ {
		go func(i uint64) {
			result := &WalletResult{}
			filename := fmt.Sprintf("%s/wallet_%d.rootkey", netroot, i)

			rootDB, err := db.MakeAccessor(filename, true, false)
			if err != nil {
				result.Error = err
				sem <- result
				return
			}
			defer rootDB.Close()

			root, err := RestoreRoot(rootDB)
			if err != nil {
				result.Error = err
				sem <- result
				return
			}

			result.Address = root.Address().String()

			m, err := mnemonic.FromKey(root.secrets.SK[:32])
			if err != nil {
				result.Error = err
				sem <- result
				return
			}

			result.Mnemonic = m
			sem <- result
		}(i)
	}
	errs := make([]error, 0)
	for i := uint64(0); i < nodenum; i++ {
		wallet := <-sem
		if wallet.Error != nil {
			errs = append(errs, err)
			continue
		}
		fmt.Fprintf(writer, "- address:  %s\n  mnemonic: %s\n", wallet.Address, wallet.Mnemonic)
	}
	if len(errs) != 0 {
		fmt.Println(errs)
		os.Exit(1)
	}
}
