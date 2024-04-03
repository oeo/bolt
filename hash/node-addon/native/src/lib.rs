use neon::prelude::*;
use bolt_hash_rust::custom_hash;

fn encode(mut cx: FunctionContext) -> JsResult<JsString> {
    let input = b"hello world";
    let result = custom_hash(input);
    Ok(cx.string(result))
}

register_module!(mut cx, {
    cx.export_function("encode", encode)
});
