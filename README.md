Ruby bindings for the [envelopers](https://github.com/cipherstash/enveloper) envelope encryption library.

Envelope encryption is a mechanism by which a plaintext is encrypted into a ciphertext using a single-use key (known as the "data key"), and then that data key is encrypted with a second key (known as the "wrapping key", or "key-encryption key", or sometimes "KEK").
The encrypted data key is then stored alongside the ciphertext, so that all that is needed for decryption is the key-encryption key and the ciphertext/encrypted data key bundle.

The benefits of this mechanism are:

1. Compromise of the key used to encrypt a plaintext (say, by short-term penetration of a process performing decryption) does not compromise all data;

2. The key-encryption key can be stored securely and entirely separate from any plaintext data, in an HSM (Hardware Security Module) or other hardened environment;

3. The entity operating the key-encryption key environment never has (direct) access to plaintexts (as would be the case if you sent the plaintext to the HSM for encryption);

4. Large volumes of data can be encrypted efficiently on a local machine, and only the small data key needs to be sent over a slow network link to be encrypted.

As you can see, the benefits of envelope encryption mostly center around environments where KEK material is HSM-managed.
Except for testing purposes, it is not common to use envelope encryption in situations where the KEK is provided directly to the envelope encryption system.


# Installation

For the most common platforms, we provide "native" gems (which have the shared object that provides the cryptographic primitives pre-compiled).
At present, we provide native gems for:

* Linux `x86_64` and `aarch64`
* macOS `x86_64` and `arm64`

On these platforms, you can just install the `enveloperb` gem via your preferred method, and it should "just work".
If it doesn't, please [report that as a bug](https://github.com/cipherstash/enveloperb/issues).

For other platforms, you will need to install the source gem, which requires that you have Rust 1.31.0 or later installed.
On ARM-based platforms, you must use Rust nightly, for SIMD intrinsics support.

## Installing from Git

If you have a burning need to install directly from a checkout of the git repository, you can do so by running `bundle install && rake install`.
As this is a source-based installation, you will need to have Rust installed, as described above.


# Usage

First off, load the library:

```ruby
require "enveloperb"
```

Then create a new cryptography engine, using your choice of wrapping key provider.
For this example, we'll use the "simple" key provider, which takes a 16 byte *binary* string as the key-encryption-key.

```ruby
require "securerandom"
kek = SecureRandom.bytes(16)

engine = Enveloperb::Simple.new(kek)
```

Now you can encrypt whatever data you like:

```ruby
ct = engine.encrypt("This is a super-important secret")
```

This produces an `Enveloperb::EncryptedRecord`, which can be turned into a (binary) string very easily:

```ruby
File.binwrite("/tmp/ciphertext", ct1.to_s)
```

To turn a binary string back into a ciphertext, just create a new `EncryptedRecord` with it:

```ruby
ct_new = Enveloperb::EncryptedRecord.new(File.binread("/tmp/ciphertext"))
```

Then you can decrypt it again:

```ruby
engine.decrypt(ct_new)  # => "This ia super-important secret"
```


## AWS KMS Key Provider

When using a locally-managed wrapping key, the benefits over direct encryption aren't significant.
The real benefits come when using a secured key provider for the wrapping key, such as AWS KMS.

To use an AWS KMS key as the wrapping key, you use an `Enveloperb::AWSKMS` instance as the cryptography engine, like so:

```ruby
engine = Enveloperb::AWSKMS.key(keyid, profile: "example", region: "xx-example-1", credentials: { ... })
```

While `keyid` is mandatory, `profile`, `region` and `credentials` are all optional.
If not specified, they will be extracted from the usual places (environment, metadata service, etc) as specified in [the AWS SDK for Rust documentation](https://docs.aws.amazon.com/sdk-for-rust/latest/dg/credentials.html).
Yes, the Rust SDK -- `enveloperb` is just a thin wrapper around a Rust library.
We are truly living in the future.

Once you have your AWS KMS cryptography engine, its usage is the familiar `#encrypt` / `#decrypt` cycle.


# Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md).


# Licence

Unless otherwise stated, everything in this repo is covered by the following
copyright notice:

    Copyright (C) 2022  CipherStash Inc.

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License version 3, as
    published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
