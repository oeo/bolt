use neon::prelude::*;
use bolt_hash::custom_hash;

fn encode(mut cx: FunctionContext) -> JsResult<JsString> {
  let input_str = cx.argument::<JsString>(0)?.value();
  let input_bytes = input_str.as_bytes();
  let hash_result = custom_hash(input_bytes);
  Ok(cx.string(hash_result))
}

register_module!(mut cx, {
  cx.export_function("encode", encode)
});

