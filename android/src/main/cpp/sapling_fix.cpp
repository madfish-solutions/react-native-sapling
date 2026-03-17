#include <jni.h>
#include <dlfcn.h>
#include <cstdlib>
#include <cstring>
#include <mutex>

/*
 * Complete replacement JNI bridge for airgap-sapling FFI functions.
 *
 * The upstream bridge (sapling.cpp) has two classes of bugs:
 *   1. Three functions call the wrong FFI symbol (ovk, pkd, ivk→address).
 *   2. local_clean() uses scalar `delete` on `new[]` buffers (UB that
 *      can corrupt the heap on Android 16's Scudo allocator).
 *
 * This file resolves every FFI symbol from the already-loaded libsapling.so
 * at runtime via dlsym and exposes them through JNI methods on SaplingFix.
 * All local buffers are freed with `delete[]` and all FFI buffers with `free()`.
 */

// ---- JNI function-name helper (two-level paste) ----

#define PASTE_(a, b) a##b
#define JNI_FN(name) PASTE_(Java_com_madfish_sapling_SaplingFix_, name)

// ---- FFI function-pointer typedefs ----

using ffi_1b   = unsigned char* (*)(const unsigned char*, size_t, size_t*);

using ffi_2b   = unsigned char* (*)(
    const unsigned char*, size_t,
    const unsigned char*, size_t,
    size_t*);

using ffi_l2b  = unsigned char* (*)(
    size_t,
    const unsigned char*, size_t,
    const unsigned char*, size_t,
    size_t*);

using ffi_blb  = unsigned char* (*)(
    const unsigned char*, size_t,
    uint64_t,
    const unsigned char*, size_t,
    size_t*);

using ffi_2bl2bl = unsigned char* (*)(
    const unsigned char*, size_t,
    const unsigned char*, size_t,
    uint64_t,
    const unsigned char*, size_t,
    uint64_t,
    size_t*);

using ffi_p3bl = unsigned char* (*)(
    void*,
    const unsigned char*, size_t,
    const unsigned char*, size_t,
    const unsigned char*, size_t,
    uint64_t,
    size_t*);

using ffi_plb  = unsigned char* (*)(
    void*, int64_t,
    const unsigned char*, size_t,
    size_t*);

using ffi_spend = unsigned char* (*)(
    void*,
    const unsigned char*, size_t,
    const unsigned char*, size_t,
    const unsigned char*, size_t,
    const unsigned char*, size_t,
    uint64_t,
    const unsigned char*, size_t,
    const unsigned char*, size_t,
    size_t*);

using ffi_sign = unsigned char* (*)(
    const unsigned char*, size_t,
    const unsigned char*, size_t,
    const unsigned char*, size_t,
    const unsigned char*, size_t,
    size_t*);

using ffi_seed_key = unsigned char* (*)(
    const unsigned char*, size_t,
    const char*,
    size_t*);

using ffi_init_params = bool (*)(
    const unsigned char*, size_t,
    const unsigned char*, size_t);

using ffi_rand_r   = unsigned char* (*)(size_t*);
using ffi_init_ctx = void* (*)();
using ffi_drop_ctx = void (*)(void*);

// ---- Resolved symbols ----

static std::once_flag resolveFlag;
static void* saplingHandle = nullptr;

static ffi_1b       fn_pak_from_xsk          = nullptr;
static ffi_blb      fn_compute_cmu           = nullptr;
static ffi_init_params fn_init_params        = nullptr;
static ffi_2b       fn_key_agreement         = nullptr;
static ffi_l2b      fn_merkle_hash           = nullptr;
static ffi_2bl2bl   fn_nullifier             = nullptr;
static ffi_p3bl     fn_output_desc_xfvk      = nullptr;
static ffi_p3bl     fn_partial_output_desc   = nullptr;
static ffi_2b       fn_derive_epk            = nullptr;
static ffi_2b       fn_payment_addr_xfvk     = nullptr;
static ffi_2b       fn_next_payment_addr     = nullptr;
static ffi_2b       fn_payment_addr_ivk      = nullptr;
static ffi_1b       fn_default_payment_addr  = nullptr;
static ffi_1b       fn_diversifier_from_addr = nullptr;
static ffi_1b       fn_pkd_from_addr         = nullptr;
static ffi_init_ctx fn_init_ctx              = nullptr;
static ffi_drop_ctx fn_drop_ctx              = nullptr;
static ffi_rand_r   fn_rand_r               = nullptr;
static ffi_plb      fn_binding_sig           = nullptr;
static ffi_spend    fn_spend_from_xsk        = nullptr;
static ffi_spend    fn_spend_from_pak        = nullptr;
static ffi_sign     fn_sign_spend            = nullptr;
static ffi_seed_key fn_xsk                   = nullptr;
static ffi_seed_key fn_xfvk                  = nullptr;
static ffi_1b       fn_xfvk_from_xsk        = nullptr;
static ffi_1b       fn_ovk_from_xfvk        = nullptr;
static ffi_1b       fn_xfvk_to_ivk          = nullptr;

static void doResolve() {
    saplingHandle = dlopen("libsapling.so", RTLD_NOW | RTLD_NOLOAD);
    if (!saplingHandle) return;

    #define SYM(var, name) var = reinterpret_cast<decltype(var)>(dlsym(saplingHandle, name))

    SYM(fn_pak_from_xsk,          "c_pak_from_xsk");
    SYM(fn_compute_cmu,           "c_compute_cmu");
    SYM(fn_init_params,           "c_init_params");
    SYM(fn_key_agreement,         "c_key_agreement");
    SYM(fn_merkle_hash,           "c_merkle_hash");
    SYM(fn_nullifier,             "c_compute_nullifier_with_xfvk");
    SYM(fn_output_desc_xfvk,     "c_output_description_from_xfvk");
    SYM(fn_partial_output_desc,   "c_partial_output_description");
    SYM(fn_derive_epk,            "c_derive_epk_from_esk");
    SYM(fn_payment_addr_xfvk,    "c_payment_address_from_xfvk");
    SYM(fn_next_payment_addr,     "c_next_payment_address_from_xfvk");
    SYM(fn_payment_addr_ivk,      "c_payment_address_from_ivk");
    SYM(fn_default_payment_addr,  "c_default_payment_address_from_xfvk");
    SYM(fn_diversifier_from_addr, "c_diversifier_from_payment_address");
    SYM(fn_pkd_from_addr,         "c_pkd_from_payment_address");
    SYM(fn_init_ctx,              "c_init_proving_context");
    SYM(fn_drop_ctx,              "c_drop_proving_context");
    SYM(fn_rand_r,                "c_rand_r");
    SYM(fn_binding_sig,           "c_binding_signature");
    SYM(fn_spend_from_xsk,       "c_spend_description_from_xsk");
    SYM(fn_spend_from_pak,       "c_spend_description_from_pak");
    SYM(fn_sign_spend,           "c_sign_spend_description_with_xsk");
    SYM(fn_xsk,                  "c_xsk");
    SYM(fn_xfvk,                "c_xfvk");
    SYM(fn_xfvk_from_xsk,       "c_xfvk_from_xsk");
    SYM(fn_ovk_from_xfvk,       "c_ovk_from_xfvk");
    SYM(fn_xfvk_to_ivk,         "c_xfvk_to_ivk");

    #undef SYM
}

static void ensureResolved() {
    std::call_once(resolveFlag, doResolve);
}

// ---- Helpers ----

struct ByteBuf {
    unsigned char* data;
    size_t         len;

    ByteBuf() : data(nullptr), len(0) {}
    ~ByteBuf() { delete[] data; }
    ByteBuf(ByteBuf&& o) noexcept : data(o.data), len(o.len) { o.data = nullptr; o.len = 0; }
    ByteBuf(const ByteBuf&) = delete;
    ByteBuf& operator=(const ByteBuf&) = delete;
};

static ByteBuf fromJni(JNIEnv* env, jbyteArray jarr) {
    ByteBuf b;
    if (!jarr) return b;
    b.len  = static_cast<size_t>(env->GetArrayLength(jarr));
    b.data = new unsigned char[b.len];
    env->GetByteArrayRegion(jarr, 0, static_cast<jsize>(b.len),
                            reinterpret_cast<jbyte*>(b.data));
    return b;
}

static jbyteArray toJni(JNIEnv* env, unsigned char* ffiPtr, size_t len) {
    if (!ffiPtr || len == 0) return nullptr;
    jbyteArray result = env->NewByteArray(static_cast<jsize>(len));
    env->SetByteArrayRegion(result, 0, static_cast<jsize>(len),
                            reinterpret_cast<jbyte*>(ffiPtr));
    free(ffiPtr);
    return result;
}

// ---- 1-byte-array → bytes ----

#define BRIDGE_1B(jniName, fnVar)                                        \
extern "C" JNIEXPORT jbyteArray JNICALL                                  \
JNI_FN(jniName)(JNIEnv* env, jclass, jbyteArray ja) {                   \
    ensureResolved();                                                    \
    if (!(fnVar) || !ja) return nullptr;                                 \
    ByteBuf a = fromJni(env, ja);                                        \
    size_t outLen = 0;                                                   \
    unsigned char* out = (fnVar)(a.data, a.len, &outLen);                \
    return toJni(env, out, outLen);                                      \
}

BRIDGE_1B(nativePakFromXsk,          fn_pak_from_xsk)
BRIDGE_1B(nativeXfvkFromXsk,         fn_xfvk_from_xsk)
BRIDGE_1B(nativeOvkFromXfvk,         fn_ovk_from_xfvk)
BRIDGE_1B(nativeXfvkToIvk,           fn_xfvk_to_ivk)
BRIDGE_1B(nativeDefaultPaymentAddr,   fn_default_payment_addr)
BRIDGE_1B(nativeDiversifierFromAddr,  fn_diversifier_from_addr)
BRIDGE_1B(nativePkdFromAddr,          fn_pkd_from_addr)

// ---- 2-byte-array → bytes ----

#define BRIDGE_2B(jniName, fnVar)                                        \
extern "C" JNIEXPORT jbyteArray JNICALL                                  \
JNI_FN(jniName)(JNIEnv* env, jclass, jbyteArray ja, jbyteArray jb) {    \
    ensureResolved();                                                    \
    if (!(fnVar) || !ja || !jb) return nullptr;                          \
    ByteBuf a = fromJni(env, ja);                                        \
    ByteBuf b = fromJni(env, jb);                                        \
    size_t outLen = 0;                                                   \
    unsigned char* out = (fnVar)(a.data, a.len, b.data, b.len, &outLen); \
    return toJni(env, out, outLen);                                      \
}

BRIDGE_2B(nativeKeyAgreement,           fn_key_agreement)
BRIDGE_2B(nativeDeriveEpkFromEsk,       fn_derive_epk)
BRIDGE_2B(nativePaymentAddressFromXfvk, fn_payment_addr_xfvk)
BRIDGE_2B(nativeNextPaymentAddress,     fn_next_payment_addr)
BRIDGE_2B(nativePaymentAddressFromIvk,  fn_payment_addr_ivk)

// ---- merkleHash: (long, bytes, bytes) → bytes ----

extern "C" JNIEXPORT jbyteArray JNICALL
JNI_FN(nativeMerkleHash)(JNIEnv* env, jclass, jlong jdepth, jbyteArray jlhs, jbyteArray jrhs) {
    ensureResolved();
    if (!fn_merkle_hash || !jlhs || !jrhs) return nullptr;
    ByteBuf lhs = fromJni(env, jlhs);
    ByteBuf rhs = fromJni(env, jrhs);
    size_t outLen = 0;
    unsigned char* out = fn_merkle_hash(
        static_cast<size_t>(jdepth), lhs.data, lhs.len, rhs.data, rhs.len, &outLen);
    return toJni(env, out, outLen);
}

// ---- computeCmu: (bytes, long, bytes) → bytes ----

extern "C" JNIEXPORT jbyteArray JNICALL
JNI_FN(nativeComputeCmu)(JNIEnv* env, jclass, jbyteArray jaddr, jlong jval, jbyteArray jrcm) {
    ensureResolved();
    if (!fn_compute_cmu || !jaddr || !jrcm) return nullptr;
    ByteBuf addr = fromJni(env, jaddr);
    ByteBuf rcm  = fromJni(env, jrcm);
    size_t outLen = 0;
    unsigned char* out = fn_compute_cmu(
        addr.data, addr.len, static_cast<uint64_t>(jval), rcm.data, rcm.len, &outLen);
    return toJni(env, out, outLen);
}

// ---- computeNullifier: (bytes, bytes, long, bytes, long) → bytes ----

extern "C" JNIEXPORT jbyteArray JNICALL
JNI_FN(nativeComputeNullifier)(JNIEnv* env, jclass,
        jbyteArray jxfvk, jbyteArray jaddr, jlong jval, jbyteArray jrcm, jlong jpos) {
    ensureResolved();
    if (!fn_nullifier || !jxfvk || !jaddr || !jrcm) return nullptr;
    ByteBuf xfvk = fromJni(env, jxfvk);
    ByteBuf addr = fromJni(env, jaddr);
    ByteBuf rcm  = fromJni(env, jrcm);
    size_t outLen = 0;
    unsigned char* out = fn_nullifier(
        xfvk.data, xfvk.len, addr.data, addr.len,
        static_cast<uint64_t>(jval), rcm.data, rcm.len,
        static_cast<uint64_t>(jpos), &outLen);
    return toJni(env, out, outLen);
}

// ---- prepareOutputDescription: (ptr, bytes, bytes, bytes, long) → bytes ----

extern "C" JNIEXPORT jbyteArray JNICALL
JNI_FN(nativeOutputDescFromXfvk)(JNIEnv* env, jclass,
        jlong jctx, jbyteArray jxfvk, jbyteArray jaddr, jbyteArray jrcm, jlong jval) {
    ensureResolved();
    if (!fn_output_desc_xfvk || !jxfvk || !jaddr || !jrcm) return nullptr;
    ByteBuf xfvk = fromJni(env, jxfvk);
    ByteBuf addr = fromJni(env, jaddr);
    ByteBuf rcm  = fromJni(env, jrcm);
    size_t outLen = 0;
    unsigned char* out = fn_output_desc_xfvk(
        reinterpret_cast<void*>(jctx),
        xfvk.data, xfvk.len, addr.data, addr.len,
        rcm.data, rcm.len, static_cast<uint64_t>(jval), &outLen);
    return toJni(env, out, outLen);
}

// ---- preparePartialOutputDescription: (ptr, bytes, bytes, bytes, long) → bytes ----

extern "C" JNIEXPORT jbyteArray JNICALL
JNI_FN(nativePartialOutputDesc)(JNIEnv* env, jclass,
        jlong jctx, jbyteArray jaddr, jbyteArray jrcm, jbyteArray jesk, jlong jval) {
    ensureResolved();
    if (!fn_partial_output_desc || !jaddr || !jrcm || !jesk) return nullptr;
    ByteBuf addr = fromJni(env, jaddr);
    ByteBuf rcm  = fromJni(env, jrcm);
    ByteBuf esk  = fromJni(env, jesk);
    size_t outLen = 0;
    unsigned char* out = fn_partial_output_desc(
        reinterpret_cast<void*>(jctx),
        addr.data, addr.len, rcm.data, rcm.len,
        esk.data, esk.len, static_cast<uint64_t>(jval), &outLen);
    return toJni(env, out, outLen);
}

// ---- createBindingSignature: (ptr, long, bytes) → bytes ----

extern "C" JNIEXPORT jbyteArray JNICALL
JNI_FN(nativeBindingSignature)(JNIEnv* env, jclass,
        jlong jctx, jlong jbal, jbyteArray jsighash) {
    ensureResolved();
    if (!fn_binding_sig || !jsighash) return nullptr;
    ByteBuf sighash = fromJni(env, jsighash);
    size_t outLen = 0;
    unsigned char* out = fn_binding_sig(
        reinterpret_cast<void*>(jctx),
        static_cast<int64_t>(jbal),
        sighash.data, sighash.len, &outLen);
    return toJni(env, out, outLen);
}

// ---- spendDescription (xsk and pak share the same signature) ----

static jbyteArray spendDescBridge(
        JNIEnv* env, ffi_spend fn, jlong jctx,
        jbyteArray jkey, jbyteArray jaddr, jbyteArray jrcm,
        jbyteArray jar, jlong jval, jbyteArray janchor, jbyteArray jpath) {
    if (!fn || !jkey || !jaddr || !jrcm || !jar || !janchor || !jpath) return nullptr;
    ByteBuf key    = fromJni(env, jkey);
    ByteBuf addr   = fromJni(env, jaddr);
    ByteBuf rcm    = fromJni(env, jrcm);
    ByteBuf ar     = fromJni(env, jar);
    ByteBuf anchor = fromJni(env, janchor);
    ByteBuf path   = fromJni(env, jpath);
    size_t outLen = 0;
    unsigned char* out = fn(
        reinterpret_cast<void*>(jctx),
        key.data, key.len, addr.data, addr.len,
        rcm.data, rcm.len, ar.data, ar.len,
        static_cast<uint64_t>(jval),
        anchor.data, anchor.len, path.data, path.len,
        &outLen);
    return toJni(env, out, outLen);
}

extern "C" JNIEXPORT jbyteArray JNICALL
JNI_FN(nativeSpendDescFromXsk)(JNIEnv* env, jclass,
        jlong jctx, jbyteArray jxsk, jbyteArray jaddr, jbyteArray jrcm,
        jbyteArray jar, jlong jval, jbyteArray janchor, jbyteArray jpath) {
    ensureResolved();
    return spendDescBridge(env, fn_spend_from_xsk, jctx,
        jxsk, jaddr, jrcm, jar, jval, janchor, jpath);
}

extern "C" JNIEXPORT jbyteArray JNICALL
JNI_FN(nativeSpendDescFromPak)(JNIEnv* env, jclass,
        jlong jctx, jbyteArray jpak, jbyteArray jaddr, jbyteArray jrcm,
        jbyteArray jar, jlong jval, jbyteArray janchor, jbyteArray jpath) {
    ensureResolved();
    return spendDescBridge(env, fn_spend_from_pak, jctx,
        jpak, jaddr, jrcm, jar, jval, janchor, jpath);
}

// ---- signSpendDescription: (bytes, bytes, bytes, bytes) → bytes ----

extern "C" JNIEXPORT jbyteArray JNICALL
JNI_FN(nativeSignSpendDesc)(JNIEnv* env, jclass,
        jbyteArray jdesc, jbyteArray jxsk, jbyteArray jar, jbyteArray jsighash) {
    ensureResolved();
    if (!fn_sign_spend || !jdesc || !jxsk || !jar || !jsighash) return nullptr;
    ByteBuf desc    = fromJni(env, jdesc);
    ByteBuf xsk     = fromJni(env, jxsk);
    ByteBuf ar      = fromJni(env, jar);
    ByteBuf sighash = fromJni(env, jsighash);
    size_t outLen = 0;
    unsigned char* out = fn_sign_spend(
        desc.data, desc.len, xsk.data, xsk.len,
        ar.data, ar.len, sighash.data, sighash.len, &outLen);
    return toJni(env, out, outLen);
}

// ---- xsk / xfvk from seed + derivation path ----

static jbyteArray keyFromSeedBridge(
        JNIEnv* env, ffi_seed_key fn, jbyteArray jseed, jstring jpath) {
    if (!fn || !jseed || !jpath) return nullptr;
    ByteBuf seed = fromJni(env, jseed);
    const char* path = env->GetStringUTFChars(jpath, nullptr);
    size_t outLen = 0;
    unsigned char* out = fn(seed.data, seed.len, path, &outLen);
    env->ReleaseStringUTFChars(jpath, path);
    return toJni(env, out, outLen);
}

extern "C" JNIEXPORT jbyteArray JNICALL
JNI_FN(nativeXsk)(JNIEnv* env, jclass, jbyteArray jseed, jstring jpath) {
    ensureResolved();
    return keyFromSeedBridge(env, fn_xsk, jseed, jpath);
}

extern "C" JNIEXPORT jbyteArray JNICALL
JNI_FN(nativeXfvk)(JNIEnv* env, jclass, jbyteArray jseed, jstring jpath) {
    ensureResolved();
    return keyFromSeedBridge(env, fn_xfvk, jseed, jpath);
}

// ---- initParameters: (bytes, bytes) → bool ----

extern "C" JNIEXPORT jboolean JNICALL
JNI_FN(nativeInitParams)(JNIEnv* env, jclass, jbyteArray jspend, jbyteArray joutput) {
    ensureResolved();
    if (!fn_init_params || !jspend || !joutput) return JNI_FALSE;
    ByteBuf spend  = fromJni(env, jspend);
    ByteBuf output = fromJni(env, joutput);
    return fn_init_params(spend.data, spend.len, output.data, output.len)
           ? JNI_TRUE : JNI_FALSE;
}

// ---- randR: () → bytes ----

extern "C" JNIEXPORT jbyteArray JNICALL
JNI_FN(nativeRandR)(JNIEnv* env, jclass) {
    ensureResolved();
    if (!fn_rand_r) return nullptr;
    size_t outLen = 0;
    unsigned char* out = fn_rand_r(&outLen);
    return toJni(env, out, outLen);
}

// ---- provingContext ----

extern "C" JNIEXPORT jlong JNICALL
JNI_FN(nativeInitProvingContext)(JNIEnv*, jclass) {
    ensureResolved();
    if (!fn_init_ctx) return 0;
    return reinterpret_cast<jlong>(fn_init_ctx());
}

extern "C" JNIEXPORT void JNICALL
JNI_FN(nativeDropProvingContext)(JNIEnv*, jclass, jlong jctx) {
    ensureResolved();
    if (!fn_drop_ctx || jctx == 0) return;
    fn_drop_ctx(reinterpret_cast<void*>(jctx));
}

// ---- diagnostics: returns a comma-separated list of UNRESOLVED symbol names ----

extern "C" JNIEXPORT jstring JNICALL
JNI_FN(nativeUnresolvedSymbols)(JNIEnv* env, jclass) {
    ensureResolved();
    std::string missing;
    #define CHK(var, name) if (!(var)) { if (!missing.empty()) missing += ','; missing += name; }
    if (!saplingHandle) { return env->NewStringUTF("libsapling.so not loaded"); }
    CHK(fn_pak_from_xsk,       "c_pak_from_xsk")
    CHK(fn_compute_cmu,        "c_compute_cmu")
    CHK(fn_init_params,        "c_init_params")
    CHK(fn_key_agreement,      "c_key_agreement")
    CHK(fn_merkle_hash,        "c_merkle_hash")
    CHK(fn_nullifier,          "c_compute_nullifier_with_xfvk")
    CHK(fn_output_desc_xfvk,  "c_output_description_from_xfvk")
    CHK(fn_partial_output_desc,"c_partial_output_description")
    CHK(fn_derive_epk,         "c_derive_epk_from_esk")
    CHK(fn_payment_addr_xfvk,  "c_payment_address_from_xfvk")
    CHK(fn_payment_addr_ivk,   "c_payment_address_from_ivk")
    CHK(fn_init_ctx,           "c_init_proving_context")
    CHK(fn_drop_ctx,           "c_drop_proving_context")
    CHK(fn_rand_r,             "c_rand_r")
    CHK(fn_binding_sig,        "c_binding_signature")
    CHK(fn_spend_from_xsk,     "c_spend_description_from_xsk")
    CHK(fn_sign_spend,         "c_sign_spend_description_with_xsk")
    CHK(fn_xsk,                "c_xsk")
    CHK(fn_xfvk,              "c_xfvk")
    CHK(fn_xfvk_from_xsk,     "c_xfvk_from_xsk")
    CHK(fn_xfvk_to_ivk,       "c_xfvk_to_ivk")
    #undef CHK
    return env->NewStringUTF(missing.empty() ? "" : missing.c_str());
}
