#[macro_use]
extern crate rutie;

#[macro_use]
extern crate lazy_static;

// I have deliberately not used more-specific symbols inside the aws_* crates because the
// names are quite generic, and in the near future when we have more providers, we'll
// almost certainly end up with naming clashes.
use aws_config;
use aws_sdk_kms;
use aws_types;
use envelopers::{CacheOptions, EncryptedRecord, EnvelopeCipher, KMSKeyProvider, SimpleKeyProvider, CachingKeyWrapper};
use std::borrow::Cow;
use tokio::runtime::Runtime;
use rutie::{Class, Encoding, Hash, Module, Object, RString, Symbol, VerifiedObject, VM};

module!(Enveloperb);
class!(EnveloperbSimple);
class!(EnveloperbAWSKMS);
class!(EnveloperbEncryptedRecord);

impl VerifiedObject for EnveloperbEncryptedRecord {
    fn is_correct_type<T: Object>(object: &T) -> bool {
        let klass = Module::from_existing("Enveloperb").get_nested_class("EncryptedRecord");
        klass.case_equals(object)
    }

    fn error_message() -> &'static str {
        "Error converting to Enveloperb::EncryptedRecord"
    }
}

pub struct SimpleCipher {
    cipher: EnvelopeCipher<CachingKeyWrapper<SimpleKeyProvider>>,
    runtime: Runtime,
}

pub struct AWSKMSCipher {
    cipher: EnvelopeCipher<CachingKeyWrapper<KMSKeyProvider>>,
    runtime: Runtime,
}

wrappable_struct!(SimpleCipher, SimpleCipherWrapper, SIMPLE_CIPHER_WRAPPER);
wrappable_struct!(AWSKMSCipher, AWSKMSCipherWrapper, AWSKMS_CIPHER_WRAPPER);
wrappable_struct!(EncryptedRecord, EncryptedRecordWrapper, ENCRYPTED_RECORD_WRAPPER);

methods!(
    EnveloperbSimple,
    rbself,

    fn enveloperb_simple_new(rbkey: RString) -> EnveloperbSimple {
        let mut key: [u8; 16] = Default::default();

        key.clone_from_slice(rbkey.unwrap().to_bytes_unchecked());

        let provider = SimpleKeyProvider::init(key);
        let cipher = EnvelopeCipher::init(CachingKeyWrapper::new(provider, CacheOptions::default()));

        let klass = Module::from_existing("Enveloperb").get_nested_class("Simple");
        return klass.wrap_data(SimpleCipher{ cipher: cipher, runtime: Runtime::new().unwrap() }, &*SIMPLE_CIPHER_WRAPPER);
    }

    fn enveloperb_simple_encrypt(rbtext: RString) -> EnveloperbEncryptedRecord {
        let cipher = rbself.get_data(&*SIMPLE_CIPHER_WRAPPER);
        let er_r = cipher.runtime.block_on(async {
            cipher.cipher.encrypt(rbtext.unwrap().to_bytes_unchecked()).await
        });
        let er = er_r.map_err(|e| VM::raise(Class::from_existing("RuntimeError"), &format!("Failed to perform encryption: {:?}", e))).unwrap();

        let klass = Module::from_existing("Enveloperb").get_nested_class("EncryptedRecord");
        return klass.wrap_data(er, &*ENCRYPTED_RECORD_WRAPPER);
    }

    fn enveloperb_simple_decrypt(rbrecord: EnveloperbEncryptedRecord) -> RString {
        let cipher = rbself.get_data(&*SIMPLE_CIPHER_WRAPPER);
        let e_record = rbrecord.unwrap();
        let record = e_record.get_data(&*ENCRYPTED_RECORD_WRAPPER);

        let vec_r = cipher.runtime.block_on(async {
            cipher.cipher.decrypt(record).await
        });
        let vec = vec_r.map_err(|e| VM::raise(Class::from_existing("RuntimeError"), &format!("Failed to perform decryption: {:?}", e))).unwrap();

        return RString::from_bytes(&vec, &Encoding::find("BINARY").unwrap());
    }
);

methods!(
    EnveloperbAWSKMS,
    rbself,

    fn enveloperb_awskms_new(rbkey: RString, rbcreds: Hash) -> EnveloperbAWSKMS {
        let raw_creds = rbcreds.unwrap();
        let rt = Runtime::new().unwrap();

        let kmsclient_config = if raw_creds.at(&Symbol::new("access_key_id")).is_nil() {
            rt.block_on(async {
                aws_config::load_from_env().await
            })
        } else {
            let rbregion = raw_creds.at(&Symbol::new("region")).try_convert_to::<RString>().unwrap();
            let region   = Some(aws_types::region::Region::new(rbregion.to_str().to_owned()));

            let rbkey_id = raw_creds.at(&Symbol::new("access_key_id")).try_convert_to::<RString>().unwrap();
            let key_id   = rbkey_id.to_str();

            let rbsecret = raw_creds.at(&Symbol::new("secret_access_key")).try_convert_to::<RString>().unwrap();
            let secret   = rbsecret.to_str();

            let token = match raw_creds.at(&Symbol::new("session_token")).try_convert_to::<RString>() {
                Ok(str) => Some(str.to_string()),
                Err(_)  => None
            };

            let aws_creds = aws_types::Credentials::from_keys(key_id, secret, token);
            let creds_provider = aws_types::credentials::SharedCredentialsProvider::new(aws_creds);

            aws_types::sdk_config::SdkConfig::builder().region(region).credentials_provider(creds_provider).build()
        };

        let kmsclient = aws_sdk_kms::Client::new(&kmsclient_config);
        let provider = KMSKeyProvider::new(kmsclient, rbkey.unwrap().to_string());
        let cipher = EnvelopeCipher::init(CachingKeyWrapper::new(provider, CacheOptions::default().with_max_bytes(100_000)));

        let klass = Module::from_existing("Enveloperb").get_nested_class("AWSKMS");
        return klass.wrap_data(AWSKMSCipher{ cipher: cipher, runtime: rt }, &*AWSKMS_CIPHER_WRAPPER);
    }

    fn enveloperb_awskms_encrypt(rbtext: RString) -> EnveloperbEncryptedRecord {
        let cipher = rbself.get_data(&*AWSKMS_CIPHER_WRAPPER);
        let er_r = cipher.runtime.block_on(async {
            cipher.cipher.encrypt(rbtext.unwrap().to_bytes_unchecked()).await
        });
        let er = er_r.map_err(|e| VM::raise(Class::from_existing("RuntimeError"), &format!("Failed to perform encryption: {:?}", e))).unwrap();

        let klass = Module::from_existing("Enveloperb").get_nested_class("EncryptedRecord");
        return klass.wrap_data(er, &*ENCRYPTED_RECORD_WRAPPER);
    }

    fn enveloperb_awskms_decrypt(rbrecord: EnveloperbEncryptedRecord) -> RString {
        let cipher = rbself.get_data(&*AWSKMS_CIPHER_WRAPPER);
        let e_record = rbrecord.unwrap();
        let record = e_record.get_data(&*ENCRYPTED_RECORD_WRAPPER);

        let vec_r = cipher.runtime.block_on(async {
            cipher.cipher.decrypt(record).await
        });
        let vec = vec_r.map_err(|e| VM::raise(Class::from_existing("RuntimeError"), &format!("Failed to perform decryption: {:?}", e))).unwrap();

        return RString::from_bytes(&vec, &Encoding::find("BINARY").unwrap());
    }
);

methods!(
    EnveloperbEncryptedRecord,
    rbself,

    fn enveloperb_encrypted_record_new(serialized_record: RString) -> EnveloperbEncryptedRecord {
        let s = serialized_record.unwrap().to_vec_u8_unchecked();
        let ct = EncryptedRecord::from_vec(s).map_err(|e| VM::raise(Class::from_existing("ArgumentError"), &format!("Failed to decode encrypted record: {:?}", e))).unwrap();

        let klass = Module::from_existing("Enveloperb").get_nested_class("EncryptedRecord");
        return klass.wrap_data(ct, &*ENCRYPTED_RECORD_WRAPPER);
    }

    fn enveloperb_encrypted_record_serialize() -> RString {
        let record = rbself.get_data(&*ENCRYPTED_RECORD_WRAPPER);

        return RString::from_bytes(&record.to_vec().map_err(|e| VM::raise(Class::from_existing("RuntimeError"), &format!("Failed to encode encrypted record: {:?}", e))).unwrap(), &Encoding::find("BINARY").unwrap());
    }
);

#[allow(non_snake_case)]
#[no_mangle]
pub extern "C" fn Init_enveloperb() {
    Module::from_existing("Enveloperb").define(|envmod| {
        envmod.define_nested_class("Simple", None).define(|klass| {
            klass.singleton_class().def_private("_new", enveloperb_simple_new);
            klass.def_private("_encrypt", enveloperb_simple_encrypt);
            klass.def_private("_decrypt", enveloperb_simple_decrypt);
        });

        envmod.define_nested_class("AWSKMS", None).define(|klass| {
            klass.singleton_class().def_private("_new", enveloperb_awskms_new);
            klass.def_private("_encrypt", enveloperb_awskms_encrypt);
            klass.def_private("_decrypt", enveloperb_awskms_decrypt);
        });

        envmod.define_nested_class("EncryptedRecord", None).define(|klass| {
            klass.singleton_class().def_private("_new", enveloperb_encrypted_record_new);
            klass.def_private("_serialize", enveloperb_encrypted_record_serialize);
        });
    });
}
